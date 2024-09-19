import Foundation

struct Friend: Codable {
    let userID: Int
    let friendID: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case friendID = "friend_id"
        case createdAt = "created_at"
    }
}