import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let name: String
    let email: String
    let locationID: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case locationID = "location_id"
    }
}