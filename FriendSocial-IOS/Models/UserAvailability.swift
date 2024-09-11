import Foundation

struct UserAvailability: Codable, Identifiable {
    let id: Int
    let userId: Int
    let dayOfWeek: String
    let startTime: Date
    let endTime: Date
    let isAvailable: Bool
    let specificDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
        case isAvailable = "is_available"
        case specificDate = "specific_date"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        dayOfWeek = try container.decode(String.self, forKey: .dayOfWeek)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ssZZZZZ"
        
        let startTimeString = try container.decode(String.self, forKey: .startTime)
        guard let startTimeDate = dateFormatter.date(from: startTimeString) else {
            throw DecodingError.dataCorruptedError(forKey: .startTime, in: container, debugDescription: "Invalid date format")
        }
        startTime = startTimeDate
        
        let endTimeString = try container.decode(String.self, forKey: .endTime)
        guard let endTimeDate = dateFormatter.date(from: endTimeString) else {
            throw DecodingError.dataCorruptedError(forKey: .endTime, in: container, debugDescription: "Invalid date format")
        }
        endTime = endTimeDate
        
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        specificDate = try container.decodeIfPresent(Date.self, forKey: .specificDate)
    }
}