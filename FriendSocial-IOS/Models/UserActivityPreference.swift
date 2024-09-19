// Add these new structs at the end of the file
struct UserActivityPreference: Codable, Identifiable {
    let id: Int
    let userID: Int
    let activityID: Int
    let frequency: Int
    let frequencyPeriod: String
    let daysOfWeek: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case activityID = "activity_id"
        case frequency
        case frequencyPeriod = "frequency_period"
        case daysOfWeek = "days_of_week"
    }
}