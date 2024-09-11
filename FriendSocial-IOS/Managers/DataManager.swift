import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared: DataManager = DataManager()
    
    @Published var currentUser: User?
    @Published var friends: [User] = []
    @Published var scheduledActivities: [ScheduledActivity] = []
    @Published var activities: [Activity] = []
    @Published var locations: [Location] = []
    @Published var activityParticipants: [Int: [ActivityParticipant]] = [:]
    @Published var isLoading: Bool = true
    @Published var participantUsers: [Int: User] = [:]
    @Published var userAvailability: [UserAvailability] = []
    
    private let apiService: APIService
    private var cancellables: Set<AnyCancellable> = []
    
    private init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    func loadInitialData(for userId: Int) {
        isLoading = true
        loadUser(id: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    self?.loadFriends(for: userId)
                    self?.loadScheduledActivities(for: userId)
                    self?.loadUserAvailability(for: userId)
                case .failure(let error):
                    print("Error loading user: \(error)")
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func loadUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
        apiService.fetchUser(id: id, completion: completion)
    }
    
    private func loadFriends(for userId: Int) {
        print("Loading friends for user \(userId)")
    }
    
    private func loadScheduledActivities(for userId: Int) {
        apiService.fetchActivityParticipantsByUserID(userID: userId) { [weak self] result in
            switch result {
            case .success(let participants):
                let scheduledActivityIds: [Int] = participants.map { $0.scheduledActivityID }
                self?.fetchScheduledActivities(ids: scheduledActivityIds)
            case .failure(let error):
                print("Error loading activity participants: \(error)")
            }
        }
    }
    
    private func fetchScheduledActivities(ids: [Int]) {
        let group: DispatchGroup = DispatchGroup()
        var fetchedActivities: [ScheduledActivity] = []
        
        for id in ids {
            group.enter()
            apiService.fetchScheduledActivity(scheduledActivityID: id) { result in
                switch result {
                case .success(let activity):
                    fetchedActivities.append(activity)
                case .failure(let error):
                    print("Error fetching scheduled activity \(id): \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.scheduledActivities = fetchedActivities.sorted { $0.scheduledAt < $1.scheduledAt }
            self?.loadActivitiesAndLocations()
        }
    }
    
    private func loadActivitiesAndLocations() {
        let group: DispatchGroup = DispatchGroup()
        var fetchedActivities: [Activity] = []
        var fetchedLocations: [Location] = []
        
        for scheduledActivity in scheduledActivities {
            group.enter()
            apiService.fetchActivity(id: scheduledActivity.activityID) { result in
                switch result {
                case .success(let activity):
                    fetchedActivities.append(activity)
                    let locationID: Int = activity.locationID
                    self.apiService.fetchLocation(id: locationID) { locationResult in
                        switch locationResult {
                        case .success(let location):
                            fetchedLocations.append(location)
                        case .failure(let error):
                            print("Error fetching location \(locationID): \(error)")
                        }
                        group.leave()
                    }
                case .failure(let error):
                    print("Error fetching activity \(scheduledActivity.activityID): \(error)")
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.activities = fetchedActivities
            self?.locations = fetchedLocations
            self?.loadActivityParticipants()
        }
    }
    
    private func loadActivityParticipants() {
        let group: DispatchGroup = DispatchGroup()
        var fetchedParticipants: [Int: [ActivityParticipant]] = [:]
        
        for scheduledActivity in scheduledActivities {
            group.enter()
            apiService.fetchActivityParticipantsByScheduledActivityID(scheduledActivityID: scheduledActivity.id) { result in
                switch result {
                case .success(let participants):
                    fetchedParticipants[scheduledActivity.id] = participants
                case .failure(let error):
                    print("Error fetching participants for activity \(scheduledActivity.id): \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.activityParticipants = fetchedParticipants
            self?.isLoading = false
            print("Initial data loading completed")
            
            self?.fetchParticipantUsers()
        }
    }
    
    private func fetchParticipantUsers() {
        let allParticipantUserIds: Set<Int> = Set(activityParticipants.values.flatMap { $0 }.map { $0.userID })
        
        for userId in allParticipantUserIds {
            apiService.fetchUser(id: userId) { [weak self] result in
                switch result {
                case .success(let user):
                    DispatchQueue.main.async {
                        self?.participantUsers[user.id] = user
                    }
                case .failure(let error):
                    print("Error fetching user \(userId): \(error)")
                }
            }
        }
    }
    
    func getActivityParticipants(for scheduledActivityId: Int) -> [ActivityParticipant] {
        return activityParticipants.values.flatMap { $0 }.filter { $0.scheduledActivityID == scheduledActivityId }
    }
    
    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
        apiService.fetchUser(id: id, completion: completion)
    }
    
    private func loadUserAvailability(for userId: Int) {
        apiService.fetchUserAvailability(userId: userId) { [weak self] result in
            switch result {
            case .success(let availability):
                DispatchQueue.main.async {
                    self?.userAvailability = availability
                }
            case .failure(let error):
                print("Error fetching user availability: \(error)")
            }
        }
    }
}
