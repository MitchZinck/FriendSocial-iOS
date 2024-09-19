import Foundation

struct ScheduledActivity: Identifiable, Codable {
    let id: Int
    let activityID: Int
    var scheduledAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case activityID = "activity_id"
        case scheduledAt = "scheduled_at"
        case isActive = "is_active"
    }

    init(id: Int, activityID: Int, scheduledAt: Date, isActive: Bool) {
        self.id = id
        self.activityID = activityID
        self.scheduledAt = scheduledAt
        self.isActive = isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        activityID = try container.decode(Int.self, forKey: .activityID)
        scheduledAt = try container.decode(Date.self, forKey: .scheduledAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
}
