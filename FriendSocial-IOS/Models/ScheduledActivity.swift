import Foundation

struct ScheduledActivity: Identifiable, Codable {
    let id: Int
    let activityID: Int
    let scheduledAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case activityID = "activity_id"
        case scheduledAt = "scheduled_at"
        case isActive = "is_active"
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        activityID = try container.decode(Int.self, forKey: .activityID)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        
        let dateString: String = try container.decode(String.self, forKey: .scheduledAt)
        let formatter: ISO8601DateFormatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date: Date = formatter.date(from: dateString) {
            scheduledAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .scheduledAt, in: container, debugDescription: "Date string does not match expected format")
        }
    }
}
