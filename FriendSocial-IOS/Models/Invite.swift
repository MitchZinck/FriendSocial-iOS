import Foundation

struct Invite: Identifiable {
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
