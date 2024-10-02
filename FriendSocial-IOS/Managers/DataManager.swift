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
    @Published var invites: [Invite] = []
    
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

                // Process invites
                await processInvites()

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

    private func processInvites() async {
        let newInvites = await withTaskGroup(of: Invite?.self) { group in
            for (scheduledActivityId, participants) in activityParticipants {
                if participants.first(where: { $0.userID == currentUser?.id && $0.inviteStatus.lowercased() == "pending" }) != nil {
                    group.addTask {
                        await self.processInvite(scheduledActivityId: scheduledActivityId, participants: participants)
                    }
                }
            }
            
            return await group.compactMap { $0 }.reduce(into: []) { $0.append($1) }
        }

        await MainActor.run {
            self.invites = newInvites
        }
    }

    private func processInvite(scheduledActivityId: Int, participants: [ActivityParticipant]) async -> Invite? {
        guard let invitedScheduledActivity = scheduledActivities.first(where: { $0.id == scheduledActivityId }),
              let invitedActivity = activities.first(where: { $0.id == invitedScheduledActivity.activityID }),
              let location = locations.first(where: { $0.id == invitedActivity.locationID }) else {
            print("Failed to process invite: missing activity or location data")
            return nil
        }

        let invitedParticipantUsers = participants.reduce(into: [Int: User]()) { result, participant in
            if let user = participantUsers[participant.userID] {
                result[participant.userID] = user
            }
        }
    
        return Invite(
            id: invitedScheduledActivity.id,
            event: invitedActivity.name, 
            emoji: invitedActivity.emoji,
            scheduledAt: invitedScheduledActivity.scheduledAt, 
            estimatedTime: invitedActivity.estimatedTime, 
            participants: participants, 
            participantUsers: invitedParticipantUsers, 
            description: invitedActivity.description, 
            locationName: location.name
        )
    }

    private func loadUser(id: Int) async throws -> User {
        return try await fetchUser(id: id)
    }
    
    private func loadFriends(for userId: Int) async {
        do {
            let friendsList = try await apiService.fetchFriends(userId: userId)
            let uniqueFriendIds = Set(friendsList.map { $0.userID == userId ? $0.friendID : $0.userID })
            
            let fetchedFriends: [User] = try await apiService.fetchUsers(ids: Array(uniqueFriendIds))

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
        return try await apiService.fetchScheduledActivities(ids: ids)
    }

    private func loadActivitiesAndLocations() async {
        do {
            let activityIDs = scheduledActivities.map { $0.activityID }
            let activities = try await self.apiService.fetchActivities(ids: activityIDs)
            
            let locationIDs = Set(activities.compactMap { $0.locationID })
            let locations = try await self.apiService.fetchLocations(ids: Array(locationIDs))
            
            let locationDict = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
            
            let fetchedActivities = activities
            let fetchedLocations = Array(locationDict.values)
            
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
            let scheduledActivityIds = scheduledActivities.map { $0.id }
            let participants = try await apiService.fetchActivityParticipantsByScheduledActivityID(scheduledActivityID: scheduledActivityIds)
            await MainActor.run {
                self.activityParticipants = Dictionary(grouping: participants, by: { $0.scheduledActivityID })
            }
        } catch {
            print("Error loading activity participants: \(error)")
        }
    }
    
    private func fetchParticipantUsers() async {
        let allParticipantUserIds: Set<Int> = Set(activityParticipants.values.flatMap { $0 }.map { $0.userID })
        do {
            let fetchedUsers = try await apiService.fetchUsers(ids: Array(allParticipantUserIds))
            await MainActor.run {
                self.participantUsers = Dictionary(uniqueKeysWithValues: fetchedUsers.map { ($0.id, $0) })
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
        
        let user = try await apiService.fetchUsers(ids: [id])
        userCache[id] = (user: user[0], timestamp: currentTime)
        return user[0]
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
        let userPreferenceIdString = String(userPreferenceId)
        let repeatScheduledActivitiesRequest = try await apiService.postCreateRepeatScheduledActivity(userPreferenceIdString, startTime, timeZone)
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
                let inviteStatus = participant.id == currentUser?.id ? "Accepted" : "Pending"
                let activityParticipant = ActivityParticipant(id: 0, userID: participant.id, scheduledActivityID: scheduledActivity.id, inviteStatus: inviteStatus)
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

    func retrieveInvitesForDate(date: Date) -> [Invite] {
        let calendar = Calendar.current
        return invites.filter { invite in
            calendar.isDate(invite.scheduledAt, inSameDayAs: date)
        }
    }

    func respondToInvite(invite: Invite, status: String) async {
        guard let currentUser = currentUser else { return }
        
        do {
            // Find the activity participant for the current user
            if let participant = invite.participants.first(where: { $0.userID == currentUser.id }) {
                // Create a new immutable participant with updated inviteStatus
                let updatedParticipant = ActivityParticipant(
                    id: participant.id,
                    userID: participant.userID,
                    scheduledActivityID: participant.scheduledActivityID,
                    inviteStatus: status
                )
                
                // Send the update to the server
                let finalUpdatedParticipant = try await apiService.updateActivityParticipant(updatedParticipant)
                
                // Update local data
                await MainActor.run {
                    // Update activityParticipants
                    if var participants = self.activityParticipants[invite.id] {
                        if let index = participants.firstIndex(where: { $0.id == finalUpdatedParticipant.id }) {
                            participants[index] = finalUpdatedParticipant
                        }
                        self.activityParticipants[invite.id] = participants
                    }
                    
                    // Remove the invite from the list
                    self.invites.removeAll { $0.id == invite.id }
                    
                    // If accepted, add to scheduledActivities if not already present
                    if status == "Accepted" {
                        if !self.scheduledActivities.contains(where: { $0.id == invite.id }) {
                            if let scheduledActivity = self.scheduledActivities.first(where: { $0.id == invite.id }) {
                                self.scheduledActivities.append(scheduledActivity)
                                self.scheduledActivities.sort { $0.scheduledAt < $1.scheduledAt }
                            }
                        }
                    }
                }
                
                print("Invite response processed successfully")
            }
        } catch {
            print("Error responding to invite: \(error)")
        }
    }
}
