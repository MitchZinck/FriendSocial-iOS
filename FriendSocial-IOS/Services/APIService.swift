import Foundation

class APIService {
    private let baseURL = "http://localhost:8080"
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private func flexibleDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatters: [DateFormatter] = [
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    return formatter
                }()
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
    }
    
    private func flexibleDateEncodingStrategy() -> JSONEncoder.DateEncodingStrategy {
        return .formatted({
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }())
    }
    
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = "Request to \(url) failed with status code \(httpResponse.statusCode)"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = self.flexibleDateDecodingStrategy()
        do {
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
        } catch {
            print("Decoding error for URL \(url): \(error)")
            throw error
        }
    }
    
    private func performPOSTRequest<T: Codable>(url: URL, body: Data) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = "POST to \(url) failed with status code \(httpResponse.statusCode)"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = self.flexibleDateDecodingStrategy()
        do {
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
        } catch {
            print("Decoding error for URL \(url): \(error)")
            throw error
        }
    }

    func fetchUsers(ids: [Int]) async throws -> [User] {
        let idsString = ids.map { String($0) }.joined(separator: ",")
        let url = URL(string: "\(baseURL)/users/\(idsString)")!
        return try await performRequest(url: url)
    }
    
    func fetchScheduledActivities(ids: [Int]) async throws -> [ScheduledActivity] {
        let idsString = ids.map { String($0) }.joined(separator: ",")
        let url = URL(string: "\(baseURL)/scheduled_activities/\(idsString)")!
        return try await performRequest(url: url)
    }

    func fetchActivities(ids: [Int]) async throws -> [Activity] {
        let idsString = ids.map { String($0) }.joined(separator: ",")
        let url = URL(string: "\(baseURL)/activities/\(idsString)")!
        return try await performRequest(url: url)
    }
    
    func fetchLocations(ids: [Int]) async throws -> [Location] {
        let idsString = ids.map { String($0) }.joined(separator: ",")
        let url = URL(string: "\(baseURL)/locations/\(idsString)")!
        return try await performRequest(url: url)
    }
    
    func fetchActivityParticipantsByUserID(userID: Int) async throws -> [ActivityParticipant] {
        let url = URL(string: "\(baseURL)/activity_participants/user/\(userID)")!
        return try await performRequest(url: url)
    }
    
    func fetchActivityParticipantsByScheduledActivityID(scheduledActivityID: [Int]) async throws -> [ActivityParticipant] {
        let idsString = scheduledActivityID.map { String($0) }.joined(separator: ",")
        let url = URL(string: "\(baseURL)/activity_participants/scheduled_activities/\(idsString)")!
        return try await performRequest(url: url)
    }
    
    func fetchUserAvailability(userId: Int) async throws -> [UserAvailability] {
        let url = URL(string: "\(baseURL)/user_availability/user/\(userId)")!
        return try await performRequest(url: url)
    }
    
    func fetchAllActivities() async throws -> [Activity] {
        let url = URL(string: "\(baseURL)/activities")!
        return try await performRequest(url: url)
    }
    
    func fetchFriends(userId: Int) async throws -> [Friend] {
        let url = URL(string: "\(baseURL)/friend/user/\(userId)")!
        return try await performRequest(url: url)
    }
    
    func postLocation(_ location: Location) async throws -> Location {
        let url = URL(string: "\(baseURL)/location")!
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let data = try encoder.encode(location)
        return try await performPOSTRequest(url: url, body: data)
    }
    
    func postActivity(_ activity: Activity) async throws -> Activity {
        let url = URL(string: "\(baseURL)/activity")!
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let data = try encoder.encode(activity)
        return try await performPOSTRequest(url: url, body: data)
    }
    
    func postScheduledActivity(_ scheduledActivity: ScheduledActivity) async throws -> ScheduledActivity {
        let url = URL(string: "\(baseURL)/scheduled_activity")!
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let data = try encoder.encode(scheduledActivity)
        return try await performPOSTRequest(url: url, body: data)
    }

    struct ScheduledActivitiesRequest: Codable {
        let activityID: Int
        let selectedDates: [String]
        let startTime: String
        let endTime: String
        let timeZone: String


        enum CodingKeys: String, CodingKey {
            case activityID = "activity_id"
            case selectedDates = "selected_dates"
            case startTime = "start_time"
            case endTime = "end_time"
            case timeZone = "time_zone"
        }
    }

    func postScheduledActivities(
        _ activityID: Int,
        _ selectedDates: [DateComponents],
        _ startTime: Date,
        _ endTime: Date,
        _ timeZone: TimeZone
    ) async throws -> [ScheduledActivity] {
        
        let url = URL(string: "\(baseURL)/scheduled_activities")!
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Convert DateComponents to ISO 8601 date strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = timeZone
        
        var formattedDates: [String] = []
        for dateComponent in selectedDates {
            if let date = Calendar.current.date(from: dateComponent) {
                let formattedDate = dateFormatter.string(from: date)
                formattedDates.append(formattedDate)
            }
        }
        
        // Convert start and end times to ISO 8601 string format
        let startTimeString = ISO8601DateFormatter().string(from: startTime)
        let endTimeString = ISO8601DateFormatter().string(from: endTime)
        
        // Create the request payload
        let requestPayload = ScheduledActivitiesRequest(
            activityID: activityID,
            selectedDates: formattedDates,
            startTime: startTimeString,
            endTime: endTimeString,
            timeZone: timeZone.identifier
        )
        
        // Format the dates array for curl output (JSON valid)
        //let formattedDatesString = formattedDates.map { "\"\($0)\"" }.joined(separator: ", ")

        // // Print curl request for testing
        // print("""
        // curl -X POST \(url) -H "Content-Type: application/json" -d '{
        //     "activity_id": \(activityID),
        //     "selected_dates": [\(formattedDatesString)],
        //     "start_time": "\(startTimeString)",
        //     "end_time": "\(endTimeString)",
        //     "time_zone": "\(timeZone.identifier)"
        // }'
        // """)
        
        // Encode the payload to JSON
        let data = try encoder.encode(requestPayload)
        
        // Perform the POST request
        return try await performPOSTRequest(url: url, body: data)
    }
    
    func postActivityParticipant(_ participant: ActivityParticipant) async throws -> ActivityParticipant {
        let url = URL(string: "\(baseURL)/activity_participant")!
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let data = try encoder.encode(participant)
        return try await performPOSTRequest(url: url, body: data)
    }
    
    func deleteScheduledActivity(id: Int) async throws {
        let url = URL(string: "\(baseURL)/scheduled_activity/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = "DELETE to \(url) failed with status code \(httpResponse.statusCode)"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
    
    func updateScheduledActivity(_ scheduledActivity: ScheduledActivity) async throws -> ScheduledActivity {
        let url = URL(string: "\(baseURL)/scheduled_activity/\(scheduledActivity.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let body = try encoder.encode(scheduledActivity)
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = "PUT to \(url) failed with status code \(httpResponse.statusCode)"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = flexibleDateDecodingStrategy()
        let updatedActivity = try decoder.decode(ScheduledActivity.self, from: data)
        return updatedActivity
    }
    
    func postUserActivityPreference(_ preference: UserActivityPreference) async throws -> UserActivityPreference {
        let url = URL(string: "\(baseURL)/user_activity_preference")!
        let encoder = JSONEncoder()
        let data = try encoder.encode(preference)
        return try await performPOSTRequest(url: url, body: data)
    }
    
    func postUserActivityPreferenceParticipant(_ participant: UserActivityPreferenceParticipant) async throws -> UserActivityPreferenceParticipant {
        let url = URL(string: "\(baseURL)/user_activity_preference_participant")!
        let encoder = JSONEncoder()
        let data = try encoder.encode(participant)
        return try await performPOSTRequest(url: url, body: data)
    }

    struct RepeatScheduledActivityRequest: Codable {
        let userPreferenceId: String
        let startTime: Date
        let timeZone: String

        enum CodingKeys: String, CodingKey {
            case userPreferenceId = "preference_id"
            case startTime = "start_time"
            case timeZone = "time_zone"
        }
    }

    func postCreateRepeatScheduledActivity(_ userPreferenceId: String, _ startTime: Date, _ timeZone: TimeZone) async throws -> [ScheduledActivity] {
        let url = URL(string: "\(baseURL)/scheduled_activity/repeat")!
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let requestPayload = RepeatScheduledActivityRequest(userPreferenceId: userPreferenceId, startTime: startTime, timeZone: timeZone.identifier)
        let data = try encoder.encode(requestPayload)
        return try await performPOSTRequest(url: url, body: data)
    }

    func updateActivityParticipant(_ participant: ActivityParticipant) async throws -> ActivityParticipant {
        let url = URL(string: "\(baseURL)/activity_participant/\(participant.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = flexibleDateEncodingStrategy()
        let data = try encoder.encode(participant)
        request.httpBody = data
        
        let (responseData, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = "PUT to \(url) failed with status code \(httpResponse.statusCode)"
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = flexibleDateDecodingStrategy()
        return try decoder.decode(ActivityParticipant.self, from: responseData)
    }
}
