import Foundation

struct Location: Identifiable, Codable {
    let id: Int
    let name: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case latitude
        case longitude
    }

    init(id: Int, name: String, address: String, latitude: Double?, longitude: Double?) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 90.0
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
    }
}
