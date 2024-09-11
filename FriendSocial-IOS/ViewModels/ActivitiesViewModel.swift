import Foundation
import Combine

class ActivitiesViewModel: ObservableObject {
    @Published var user: User?
    @Published var userScheduledActivities: [ScheduledActivity] = []
    @Published var activities: [Activity] = []
    @Published var locations: [Location] = []
    @Published var activityParticipants: [Int: [ActivityParticipant]] = [:]
    @Published var participantUsers: [Int: User] = [:]
    @Published var hasNotifications: Bool = false
    
    private let dataManager: DataManager
    private var cancellables: Set<AnyCancellable> = []
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
        setupBindings()
    }
    
    private func setupBindings() {
        dataManager.$currentUser
            .assign(to: \.user, on: self)
            .store(in: &cancellables)
        
        dataManager.$scheduledActivities
            .assign(to: \.userScheduledActivities, on: self)
            .store(in: &cancellables)
        
        dataManager.$activities
            .assign(to: \.activities, on: self)
            .store(in: &cancellables)
        
        dataManager.$locations
            .assign(to: \.locations, on: self)
            .store(in: &cancellables)
        
        dataManager.$activityParticipants
            .assign(to: \.activityParticipants, on: self)
            .store(in: &cancellables)
        
        dataManager.$participantUsers
            .assign(to: \.participantUsers, on: self)
            .store(in: &cancellables)
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
