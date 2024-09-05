import Foundation

struct ActivityParticipant: Codable {
    let id: Int
    let userID: Int
    let scheduledActivityID: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case scheduledActivityID = "scheduled_activity_id"
    }
}
