import Foundation

struct Location: Identifiable, Codable {
    let id: Int
    let name: String
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case city
        case state
        case zipCode = "zip_code"
        case country
        case latitude
        case longitude
    }
}
