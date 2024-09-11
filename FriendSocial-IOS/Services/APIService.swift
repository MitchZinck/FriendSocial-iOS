import Foundation

class APIService {
    private let baseURL: String = "http://localhost:8080"
    
    private func performRequest<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error: Error = error {
                completion(.failure(error))
                return
            }
            guard let data: Data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let responseString: String = String(data: data, encoding: .utf8) {
                print("Raw response for \(url.absoluteString):")
                print(responseString)
            }
            
            do {
                let decodedData: T = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/users/\(id)")!
        performRequest(url: url, completion: completion)
    }
    
    func fetchScheduledActivity(scheduledActivityID: Int, completion: @escaping (Result<ScheduledActivity, Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/scheduled_activity/\(scheduledActivityID)")!
        performRequest(url: url, completion: completion)
    }
    
    func fetchActivity(id: Int, completion: @escaping (Result<Activity, Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/activity/\(id)")!
        performRequest(url: url, completion: completion)
    }
    
    func fetchLocation(id: Int, completion: @escaping (Result<Location, Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/location/\(id)")!
        performRequest(url: url, completion: completion)
    }
    
    func fetchActivityParticipantsByUserID(userID: Int, completion: @escaping (Result<[ActivityParticipant], Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/activity_participants/user/\(userID)")!
        performRequest(url: url, completion: completion)
    }

    func fetchActivityParticipantsByScheduledActivityID(scheduledActivityID: Int, completion: @escaping (Result<[ActivityParticipant], Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/activity_participants/scheduled_activity/\(scheduledActivityID)")!
        performRequest(url: url, completion: completion)
    }
    
    func fetchUserAvailability(userId: Int, completion: @escaping (Result<[UserAvailability], Error>) -> Void) {
        let url: URL = URL(string: "\(baseURL)/user_availability/user/\(userId)")!
        performRequest(url: url, completion: completion)
    }
}