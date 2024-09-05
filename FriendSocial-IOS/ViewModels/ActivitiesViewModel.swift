import Foundation

class ActivitiesViewModel: ObservableObject {
    @Published var user: User?
    @Published var userScheduledActivities: [ScheduledActivity] = []
    @Published var activities: [Activity] = []
    @Published var locations: [Location] = []
    @Published var activityParticipants: [Int: [ActivityParticipant]] = [:]
    @Published var participantUsers: [Int: User] = [:]
    
    private let apiService: APIService
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
        fetchAllData(for: 3) // Assuming user ID 3 for now
    }
    
    func fetchAllData(for userId: Int) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let user = self.fetchUser(id: userId)
            let activityParticipants = self.fetchActivityParticipantsByUserID(for: userId)
            var fetchedScheduledActivities: [ScheduledActivity] = []
            var fetchedActivities: [Activity] = []
            var fetchedLocations: [Location] = []
            var fetchedParticipantUsers: [Int: User] = [:]
            
            for activityParticipant in activityParticipants {
                if let scheduledActivity = self.fetchUserScheduledActivity(scheduledActivityID: activityParticipant.scheduledActivityID) {
                    fetchedScheduledActivities.append(scheduledActivity)
                    if let activity = self.fetchActivity(id: scheduledActivity.activityID) {
                        fetchedActivities.append(activity)
                        if let location = self.fetchLocation(id: activity.locationID) {
                            fetchedLocations.append(location)
                        }
                    }

                    let participants = self.fetchActivityParticipantsByScheduledActivityID(for: scheduledActivity.id)
                    for participant in participants {
                        if let participantUser = self.fetchUser(id: participant.userID) {
                            fetchedParticipantUsers[participant.userID] = participantUser
                        }
                    }
                }
            }
            
            // Update published properties
            DispatchQueue.main.async {
                self.user = user
                self.activityParticipants = Dictionary(grouping: activityParticipants, by: { $0.scheduledActivityID })
                self.userScheduledActivities = fetchedScheduledActivities
                self.activities = fetchedActivities
                self.locations = fetchedLocations
                self.participantUsers = fetchedParticipantUsers
                self.objectWillChange.send()
            }
        }
    }
    
    func fetchUser(id: Int) -> User? {
        var fetchedUser: User?
        let semaphore = DispatchSemaphore(value: 0)
        
        apiService.fetchUser(id: id) { result in
            switch result {
            case .success(let user):
                fetchedUser = user
            case .failure(let error):
                print("Error fetching user: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return fetchedUser
    }
    
    func fetchActivityParticipantsByUserID(for userId: Int) -> [ActivityParticipant] {
        var fetchedParticipants: [ActivityParticipant] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        apiService.fetchActivityParticipantsByUserID(userID: userId) { result in
            switch result {
            case .success(let participants):
                fetchedParticipants = participants
            case .failure(let error):
                print("Error fetching activity participants: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return fetchedParticipants
    }

    func fetchActivityParticipantsByScheduledActivityID(for scheduledActivityID: Int) -> [ActivityParticipant] {
        var fetchedParticipants: [ActivityParticipant] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        apiService.fetchActivityParticipantsByScheduledActivityID(scheduledActivityID: scheduledActivityID) { result in
            switch result {
            case .success(let participants):
                fetchedParticipants = participants
            case .failure(let error):
                print("Error fetching activity participants: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return fetchedParticipants
    }
    
    func fetchUserScheduledActivity(scheduledActivityID: Int) -> ScheduledActivity? {
        var fetchedActivity: ScheduledActivity?
        let semaphore = DispatchSemaphore(value: 0)
        
        apiService.fetchScheduledActivity(scheduledActivityID: scheduledActivityID) { result in
            switch result {
            case .success(let scheduledActivity):
                fetchedActivity = scheduledActivity
            case .failure(let error):
                print("Error fetching user scheduled activities: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return fetchedActivity
    }
    
    func fetchActivity(id: Int) -> Activity? {
        var fetchedActivity: Activity?
        let semaphore = DispatchSemaphore(value: 0)
        
        apiService.fetchActivity(id: id) { result in
            switch result {
            case .success(let activity):
                fetchedActivity = activity
            case .failure(let error):
                print("Error fetching activity: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return fetchedActivity
    }
    
    func fetchLocation(id: Int) -> Location? {
        var fetchedLocation: Location?
        let semaphore = DispatchSemaphore(value: 0)
        
        apiService.fetchLocation(id: id) { result in
            switch result {
            case .success(let location):
                fetchedLocation = location
            case .failure(let error):
                print("Error fetching location: \(error)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return fetchedLocation
    }
    
    func getLocation(for locationID: Int) -> Location? {
        return locations.first { $0.id == locationID }
    }
    
    func cancelActivity(_ scheduledActivity: ScheduledActivity) {
        // Implementation
    }
    
    func rescheduleActivity(_ scheduledActivity: ScheduledActivity) {
        // Implementation
    }
}
