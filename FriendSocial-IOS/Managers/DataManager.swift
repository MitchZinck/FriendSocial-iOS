import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var currentUser: User?
    @Published var friends: [User] = []
    @Published var scheduledActivities: [ScheduledActivity] = []
    @Published var activities: [Activity] = []
    @Published var locations: [Location] = []
    @Published var activityParticipants: [Int: [ActivityParticipant]] = [:]
    @Published var isLoading: Bool = true
    @Published var participantUsers: [Int: User] = [:]
    @Published var userAvailability: [UserAvailability] = []
    @Published var userActivityPreferences: [UserActivityPreference] = []
    
    private let apiService: APIService
    private var userCache: [Int: (user: User, timestamp: Date)] = [:]
    private let cacheExpirationTime: TimeInterval = 600 // 10 minutes in seconds
    
    private init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    func loadInitialData(for userId: Int) {
        isLoading = true
        Task {
            do {
                let user = try await loadUser(id: userId)
                await MainActor.run {
                    self.currentUser = user
                }
                
                // Run tasks concurrently
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await self.loadFriends(for: userId) }
                    group.addTask { await self.loadScheduledActivities(for: userId) }
                    group.addTask { await self.loadUserAvailability(for: userId) }
                }
                
                await MainActor.run {
                    self.isLoading = false
                    print("Initial data loading completed")
                }
            } catch {
                print("Error loading initial data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadUser(id: Int) async throws -> User {
        return try await fetchUser(id: id)
    }
    
    private func loadFriends(for userId: Int) async {
        do {
            let friendsList = try await apiService.fetchFriends(userId: userId)
            let uniqueFriendIds = Set(friendsList.map { $0.userID == userId ? $0.friendID : $0.userID })
            
            let fetchedFriends: [User] = try await withThrowingTaskGroup(of: User.self) { group in
                for friendId in uniqueFriendIds {
                    group.addTask {
                        return try await self.fetchUser(id: friendId)
                    }
                }
                var users: [User] = []
                for try await user in group {
                    users.append(user)
                }
                return users
            }
            await MainActor.run {
                self.friends = fetchedFriends
            }
        } catch {
            print("Error loading friends: \(error)")
        }
    }
    
    private func loadScheduledActivities(for userId: Int) async {
        do {
            let participants = try await apiService.fetchActivityParticipantsByUserID(userID: userId)
            if participants.isEmpty {
                print("No activity participants found for user \(userId)")
            } else {
                let scheduledActivityIds = participants.map { $0.scheduledActivityID }
                let scheduledActivities = try await fetchScheduledActivities(ids: scheduledActivityIds)
                await MainActor.run {
                    self.scheduledActivities = scheduledActivities.sorted { $0.scheduledAt < $1.scheduledAt }
                }
                await loadActivitiesAndLocations()
                await loadActivityParticipants()
                await fetchParticipantUsers()
            }
        } catch {
            print("Error loading scheduled activities: \(error)")
        }
    }

    
    private func fetchScheduledActivities(ids: [Int]) async throws -> [ScheduledActivity] {
        return try await withThrowingTaskGroup(of: ScheduledActivity.self) { group in
            for id in ids {
                group.addTask {
                    return try await self.apiService.fetchScheduledActivity(scheduledActivityID: id)
                }
            }
            var fetchedActivities: [ScheduledActivity] = []
            for try await activity in group {
                fetchedActivities.append(activity)
            }
            return fetchedActivities
        }
    }

    private func loadActivitiesAndLocations() async {
        do {
            let results = try await withThrowingTaskGroup(of: (Activity, Location?).self) { group in
                for scheduledActivity in scheduledActivities {
                    group.addTask {
                        let activity = try await self.apiService.fetchActivity(id: scheduledActivity.activityID)
                        var location: Location? = nil
                        if let locationID = activity.locationID {
                            location = try await self.apiService.fetchLocation(id: locationID)
                        }
                        return (activity, location)
                    }
                }
                var results: [(Activity, Location?)] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            
            let fetchedActivities = results.map { $0.0 }
            let fetchedLocations = results.compactMap { $0.1 }
            
            await MainActor.run {
                self.activities = fetchedActivities
                self.locations = fetchedLocations
            }
        } catch {
            print("Error loading activities and locations: \(error)")
        }
    }
        
    private func loadActivityParticipants() async {
        do {
            let results = try await withThrowingTaskGroup(of: (Int, [ActivityParticipant]).self) { group in
                for scheduledActivity in scheduledActivities {
                    group.addTask {
                        let participants = try await self.apiService.fetchActivityParticipantsByScheduledActivityID(scheduledActivityID: scheduledActivity.id)
                        return (scheduledActivity.id, participants)
                    }
                }
                var participantsDict: [Int: [ActivityParticipant]] = [:]
                for try await (scheduledActivityId, participants) in group {
                    participantsDict[scheduledActivityId] = participants
                }
                return participantsDict
            }
            await MainActor.run {
                self.activityParticipants = results
            }
        } catch {
            print("Error loading activity participants: \(error)")
        }
    }
    
    private func fetchParticipantUsers() async {
        let allParticipantUserIds: Set<Int> = Set(activityParticipants.values.flatMap { $0 }.map { $0.userID })
        do {
            let fetchedUsers = try await withThrowingTaskGroup(of: (Int, User).self) { group in
                for userId in allParticipantUserIds {
                    group.addTask {
                        let user = try await self.fetchUser(id: userId)
                        return (userId, user)
                    }
                }
                var usersDict: [Int: User] = [:]
                for try await (userId, user) in group {
                    usersDict[userId] = user
                }
                return usersDict
            }
            await MainActor.run {
                self.participantUsers = fetchedUsers
            }
        } catch {
            print("Error fetching participant users: \(error)")
        }
    }
    
    func getActivityParticipants(for scheduledActivityId: Int) -> [ActivityParticipant] {
        return activityParticipants[scheduledActivityId] ?? []
    }
    
    func fetchUser(id: Int) async throws -> User {
        let currentTime = Date()
        if let cachedData = userCache[id],
           currentTime.timeIntervalSince(cachedData.timestamp) < cacheExpirationTime {
            return cachedData.user
        }
        
        let user = try await apiService.fetchUser(id: id)
        userCache[id] = (user: user, timestamp: currentTime)
        return user
    }
    
    private func loadUserAvailability(for userId: Int) async {
        do {
            let availability = try await apiService.fetchUserAvailability(userId: userId)
            DispatchQueue.main.async {
                self.userAvailability = availability
            }
        } catch {
            print("Error fetching user availability: \(error)")
        }
    }
    
    func saveNewScheduledActivity(location: Location, activity: Activity, selectedDates: [DateComponents], startTime: Date, endTime: Date, participants: [User], isRepeating: Bool, repeatFrequency: Int, repeatUnit: String, selectedDays: [Int]) async throws {
        // Step 1: Check if location exists, if not, create a new one
        let savedLocation: Location
        if let existingLocation = locations.first(where: { $0.name == location.name && $0.address == location.address }) {
            savedLocation = existingLocation
        } else {
            savedLocation = try await apiService.postLocation(location)
            await MainActor.run {
                self.addLocation(savedLocation)
            }
        }

        // Step 2: Check if activity exists, if not, create a new one
        let savedActivity: Activity
        if let existingActivity = activities.first(where: { $0.name == activity.name && $0.description == activity.description }) {
            savedActivity = existingActivity
        } else {
            var updatedActivity = activity
            updatedActivity.locationID = savedLocation.id
            savedActivity = try await apiService.postActivity(updatedActivity)
            await MainActor.run {
                self.addActivity(savedActivity)
            }
        }

        // Create and post the initial scheduled activity
        let timeZone = TimeZone.current
        let scheduledActivities = try await createScheduledActivities(activity: savedActivity, selectedDates: selectedDates, startTime: startTime, endTime: endTime, timeZone: timeZone)
        
        // Create and post activity participants
        try await createActivityParticipants(scheduledActivities: scheduledActivities, participants: participants)

        if isRepeating {
            // Create and save user activity preference
            let preference = UserActivityPreference(
                id: 0,
                userID: currentUser!.id,
                activityID: savedActivity.id,
                frequency: repeatFrequency,
                frequencyPeriod: repeatUnit.lowercased(),
                daysOfWeek: selectedDays.map { String($0) }.joined(separator: ",")
            )
            let savedPreference = try await apiService.postUserActivityPreference(preference)

            // Create and save user activity preference participants
            for participant in participants {
                let preferenceParticipant = UserActivityPreferenceParticipant(
                    id: 0,
                    userActivityPreferenceID: savedPreference.id,
                    userID: participant.id
                )
                _ = try await apiService.postUserActivityPreferenceParticipant(preferenceParticipant)
            }

            _ = try await createRepeatScheduledActivities(userPreferenceId: savedPreference.id, startTime: startTime, timeZone: timeZone)
        }
    }

    private func createRepeatScheduledActivities(userPreferenceId: Int, startTime: Date, timeZone: TimeZone) async throws -> [ScheduledActivity] {
        let repeatScheduledActivitiesRequest = try await apiService.postCreateRepeatScheduledActivity(userPreferenceId, startTime, timeZone)
        repeatScheduledActivitiesRequest.forEach { scheduledActivity in
            DispatchQueue.main.async {
                self.addScheduledActivity(scheduledActivity)
            }
        }
        return repeatScheduledActivitiesRequest
    }
    
    private func createScheduledActivities(activity: Activity, selectedDates: [DateComponents], startTime: Date, endTime: Date, timeZone: TimeZone) async throws -> [ScheduledActivity] {
        let savedScheduledActivities = try await apiService.postScheduledActivities(activity.id, selectedDates, startTime, endTime, timeZone)

        return savedScheduledActivities
    }
    
    private func createActivityParticipants(scheduledActivities: [ScheduledActivity], participants: [User]) async throws {
        for scheduledActivity in scheduledActivities {
            for participant in participants {
                let activityParticipant = ActivityParticipant(id: 0, userID: participant.id, scheduledActivityID: scheduledActivity.id, inviteStatus: "Pending")
                let savedActivityParticipant = try await apiService.postActivityParticipant(activityParticipant)
                await MainActor.run {
                    self.addActivityParticipant(savedActivityParticipant)
                }
            }
        }
    }
    
    // Helper methods to update local data
    private func addLocation(_ location: Location) {
        if !self.locations.contains(where: { $0.id == location.id }) {
            self.locations.append(location)
        }
    }
    
    private func addActivity(_ activity: Activity) {
        if !self.activities.contains(where: { $0.id == activity.id }) {
            self.activities.append(activity)
        }
    }
    
    private func addScheduledActivity(_ scheduledActivity: ScheduledActivity) {
        if !self.scheduledActivities.contains(where: { $0.id == scheduledActivity.id }) {
            self.scheduledActivities.append(scheduledActivity)
            self.scheduledActivities.sort { $0.scheduledAt < $1.scheduledAt }
        }
    }
    
    private func addActivityParticipant(_ participant: ActivityParticipant) {
        if self.activityParticipants[participant.scheduledActivityID] == nil {
            self.activityParticipants[participant.scheduledActivityID] = []
        }
        if !self.activityParticipants[participant.scheduledActivityID]!.contains(where: { $0.id == participant.id }) {
            self.activityParticipants[participant.scheduledActivityID]!.append(participant)
        }
    }

    func cancelScheduledActivity(_ scheduledActivity: ScheduledActivity) async throws {
        // Call API to cancel the scheduled activity
        try await apiService.deleteScheduledActivity(id: scheduledActivity.id)
        
        // Update local data
        DispatchQueue.main.async {
            self.scheduledActivities.removeAll { $0.id == scheduledActivity.id }
            self.activityParticipants[scheduledActivity.id] = nil
        }
    }
    
    func rescheduleScheduledActivity(_ scheduledActivity: ScheduledActivity, to newDate: Date) async throws {
        var updatedActivity = scheduledActivity
        updatedActivity.scheduledAt = newDate
        
        // Call API to update the scheduled activity
        let savedActivity = try await apiService.updateScheduledActivity(updatedActivity)
        
        // Update local data
        DispatchQueue.main.async {
            if let index = self.scheduledActivities.firstIndex(where: { $0.id == savedActivity.id }) {
                self.scheduledActivities[index] = savedActivity
                self.scheduledActivities.sort { $0.scheduledAt < $1.scheduledAt }
            }
        }
    }
}