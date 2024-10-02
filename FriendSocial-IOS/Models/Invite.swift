import Foundation

struct Invite: Identifiable, Equatable {
    let id: Int
    let event: String
    let emoji: String
    let scheduledAt: Date
    let estimatedTime: String
    let participants: [ActivityParticipant]
    let participantUsers: [Int: User]
    let description: String
    let locationName: String
}
