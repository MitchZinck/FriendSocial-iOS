import Foundation

struct Activity: Identifiable, Codable {
    var id: Int
    let name: String
    let description: String
    let estimatedTime: String
    var locationID: Int?  // Make locationID optional
    let userCreated: Bool
    let emoji: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case estimatedTime = "estimated_time"
        case locationID = "location_id"
        case userCreated = "user_created"
        case emoji
    }
}
