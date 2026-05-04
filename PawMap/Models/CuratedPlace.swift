import Foundation
import CoreLocation
import MapKit

// MARK: - Curated Place Model
struct CuratedPlace: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let type: PlaceType
    let address: String
    /// Short line for list UI, e.g. "San Francisco, CA" (not the full street address).
    let locationLabel: String?
    let latitude: Double
    let longitude: Double
    let imageURL: String
    /// If `imageURL` fails to load (404, etc.), try this landmark / nearby photo next.
    let fallbackImageURL: String?
    let description: String
    let isNational: Bool // true for National Favorites, false for Nearby Favorites
    let rating: Double
    let tags: [String]
    let amenities: [String]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Line shown under the place name in lists (explicit label or best-effort from address).
    var displayLocationLine: String {
        if let s = locationLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }
        let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if parts.count >= 2 {
            return parts.suffix(2).joined(separator: ", ")
        }
        return address
    }
    
    enum PlaceType: String, CaseIterable, Codable {
        case park = "Dog Park"
        case cafe = "Cafe"
        case beach = "Beach"
        case trail = "Trail"
        case camp = "Camp"
        case restaurant = "Restaurant"
        case shop = "Shop"
        case hotel = "Hotel"
        /// Walkable downtown / shopping district where many storefronts welcome leashed dogs.
        case dogFriendlyDistrict = "Dog-Friendly District"
        case other = "Other"
        
        var iconName: String {
            switch self {
            case .park: return "tree.fill"
            case .cafe: return "cup.and.saucer.fill"
            case .beach: return "beach.umbrella.fill"
            case .trail: return "figure.hiking"
            case .camp: return "tent.fill"
            case .restaurant: return "fork.knife"
            case .shop: return "bag.fill"
            case .hotel: return "bed.double.fill"
            case .dogFriendlyDistrict: return "building.2.fill"
            case .other: return "star.fill"
            }
        }
        
        var color: String {
            switch self {
            case .park: return "green"
            case .cafe: return "brown"
            case .beach: return "blue"
            case .trail: return "orange"
            case .camp: return "purple"
            case .restaurant: return "red"
            case .shop: return "pink"
            case .hotel: return "indigo"
            case .dogFriendlyDistrict: return "teal"
            case .other: return "gray"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, address, locationLabel, latitude, longitude, imageURL, fallbackImageURL
        case description, isNational, rating, tags, amenities
    }
    
    init(
        id: String,
        name: String,
        type: PlaceType,
        address: String,
        locationLabel: String? = nil,
        latitude: Double,
        longitude: Double,
        imageURL: String,
        fallbackImageURL: String? = nil,
        description: String,
        isNational: Bool,
        rating: Double,
        tags: [String],
        amenities: [String]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.address = address
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
        self.imageURL = imageURL
        self.fallbackImageURL = fallbackImageURL
        self.description = description
        self.isNational = isNational
        self.rating = rating
        self.tags = tags
        self.amenities = amenities
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(PlaceType.self, forKey: .type)
        address = try c.decode(String.self, forKey: .address)
        locationLabel = try c.decodeIfPresent(String.self, forKey: .locationLabel)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        imageURL = try c.decode(String.self, forKey: .imageURL)
        fallbackImageURL = try c.decodeIfPresent(String.self, forKey: .fallbackImageURL)
        description = try c.decode(String.self, forKey: .description)
        isNational = try c.decode(Bool.self, forKey: .isNational)
        rating = try c.decode(Double.self, forKey: .rating)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        amenities = try c.decodeIfPresent([String].self, forKey: .amenities) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encode(address, forKey: .address)
        try c.encodeIfPresent(locationLabel, forKey: .locationLabel)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encode(imageURL, forKey: .imageURL)
        try c.encodeIfPresent(fallbackImageURL, forKey: .fallbackImageURL)
        try c.encode(description, forKey: .description)
        try c.encode(isNational, forKey: .isNational)
        try c.encode(rating, forKey: .rating)
        try c.encode(tags, forKey: .tags)
        try c.encode(amenities, forKey: .amenities)
    }
}

// MARK: - Distance Calculation
extension CuratedPlace {
    /// Calculate distance from user's location in miles
    func distance(from location: CLLocation) -> Double {
        let placeLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distanceInMeters = location.distance(from: placeLocation)
        let distanceInMiles = distanceInMeters * 0.000621371 // Convert meters to miles
        return distanceInMiles
    }
    
    /// Check if place is within specified radius (in miles)
    func isWithinRadius(_ radiusMiles: Double, from location: CLLocation) -> Bool {
        return distance(from: location) <= radiusMiles
    }
}

