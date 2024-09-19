struct UserActivityPreferenceParticipant: Codable, Identifiable {
    let id: Int
    let userActivityPreferenceID: Int
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userActivityPreferenceID = "user_activity_preference_id"
        case userID = "user_id"
    }
}
