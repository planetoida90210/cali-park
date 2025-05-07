import Foundation
import CoreLocation

// MARK: - Park Model
struct Park: Identifiable, Codable, Equatable, Hashable {
    // MARK: Properties
    let id: UUID
    var name: String
    var city: String
    var coordinate: CLLocationCoordinate2D
    var distance: Double? // Calculated at runtime
    var rating: Double
    var images: [URL]
    var description: String
    var isFavorite: Bool
    var equipments: [String]
    var tags: [ParkTag]

    // Custom Equatable – include key visual fields so SwiftUI diff recognises updates (esp. isFavorite)
    static func == (lhs: Park, rhs: Park) -> Bool {
        lhs.id == rhs.id &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.name == rhs.name &&
        lhs.city == rhs.city &&
        lhs.distance == rhs.distance &&
        lhs.rating == rhs.rating
    }

    // Custom Codable because CLLocationCoordinate2D isn't Codable by default
    enum CodingKeys: String, CodingKey {
        case id, name, city, latitude, longitude, distance, rating, images, description, isFavorite, equipments, tags
    }

    init(id: UUID = UUID(),
         name: String,
         city: String,
         coordinate: CLLocationCoordinate2D,
         distance: Double? = nil,
         rating: Double,
         images: [URL] = [],
         description: String,
         isFavorite: Bool = false,
         equipments: [String] = [],
         tags: [ParkTag] = []) {
        self.id = id
        self.name = name
        self.city = city
        self.coordinate = coordinate
        self.distance = distance
        self.rating = rating
        self.images = images
        self.description = description
        self.isFavorite = isFavorite
        self.equipments = equipments
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        city = try container.decode(String.self, forKey: .city)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        rating = try container.decode(Double.self, forKey: .rating)
        images = try container.decode([URL].self, forKey: .images)
        description = try container.decode(String.self, forKey: .description)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        equipments = try container.decode([String].self, forKey: .equipments)
        tags = try container.decodeIfPresent([ParkTag].self, forKey: .tags) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(city, forKey: .city)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encode(rating, forKey: .rating)
        try container.encode(images, forKey: .images)
        try container.encode(description, forKey: .description)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(equipments, forKey: .equipments)
        try container.encode(tags, forKey: .tags)
    }

    // Custom Hashable – wystarczy unikalne id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Mock Data
extension Park {
    static let mock: [Park] = [
        Park(
            id: UUID(),
            name: "Street Workout Park",
            city: "Warsaw",
            coordinate: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
            distance: 0.4,
            rating: 4.5,
            images: [],
            description: "Solid pull-up bars, parallel bars and more.",
            isFavorite: false,
            equipments: [
                "Pull-up bar", "Dip bar", "Monkey bars", "Rings", "Push-up handles",
                "Climbing rope", "Box jump", "Resistance bands", "Parallel bars", "Tires",
                "Battle ropes", "Sledge hammer", "Kettlebell", "Medicine ball"
            ],
            tags: [.shade, .light, .water]
        ),
        Park(
            id: UUID(),
            name: "Green Gym",
            city: "Kraków",
            coordinate: CLLocationCoordinate2D(latitude: 50.0647, longitude: 19.9450),
            distance: 2.1,
            rating: 4.9,
            images: [],
            description: "Shaded area with rubber flooring.",
            isFavorite: true,
            equipments: [
                "Pull-up bar", "Dip bar", "Monkey bars", "Rings", "Push-up handles",
                "Parallel bars", "Kettlebell", "Medicine ball"
            ],
            tags: [.roof, .light]
        )
    ]
} 