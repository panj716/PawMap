import Foundation
import CoreLocation
import MapKit
import FirebaseFirestore

/// Refactored Place model for Firebase integration
struct Place: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let type: PlaceType
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let tags: [String]
    let notes: String
    let createdBy: String // User ID who created this place
    let createdAt: Date
    let updatedAt: Date
    let isVerified: Bool
    let reportCount: Int
    let images: [String] // Firebase Storage URLs
    let dogAmenities: DogAmenities
    let restaurantSeatingType: RestaurantSeatingType? // Only for restaurant type places
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var mapAnnotation: MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = name
        annotation.subtitle = "\(type.displayName) • \(String(format: "%.1f", rating))★"
        return annotation
    }
    
    /// Calculate distance from user's location in kilometers
    func distance(from location: CLLocation) -> Double {
        let placeLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distanceInMeters = location.distance(from: placeLocation)
        let distanceInKilometers = distanceInMeters / 1000.0 // Convert meters to kilometers
        return distanceInKilometers
    }
    
    // Coding keys to exclude computed properties
    enum CodingKeys: String, CodingKey {
        case id, name, type, address, latitude, longitude, rating, tags, notes
        case createdBy, createdAt, updatedAt, isVerified, reportCount, images, dogAmenities
        case restaurantSeatingType
    }
    
    // MARK: - Initializers
    
    init(id: String = UUID().uuidString, name: String, type: PlaceType, address: String, latitude: Double, longitude: Double, rating: Double = 0.0, tags: [String] = [], notes: String, createdBy: String, createdAt: Date = Date(), updatedAt: Date = Date(), isVerified: Bool = false, reportCount: Int = 0, images: [String] = [], dogAmenities: DogAmenities = DogAmenities.empty, restaurantSeatingType: RestaurantSeatingType? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.tags = tags
        self.notes = notes
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isVerified = isVerified
        self.reportCount = reportCount
        self.images = images
        self.dogAmenities = dogAmenities
        self.restaurantSeatingType = restaurantSeatingType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(PlaceType.self, forKey: .type)
        address = try container.decode(String.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)

        // Backward-compatible defaults for legacy documents.
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0.0
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy) ?? "system"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        reportCount = try container.decodeIfPresent(Int.self, forKey: .reportCount) ?? 0
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        dogAmenities = try container.decodeIfPresent(DogAmenities.self, forKey: .dogAmenities) ?? .empty
        restaurantSeatingType = try container.decodeIfPresent(RestaurantSeatingType.self, forKey: .restaurantSeatingType)
    }
    
    // MARK: - Update Methods
    
    func updatingRating(_ newRating: Double) -> Place {
        return Place(
            id: id,
            name: name,
            type: type,
            address: address,
            latitude: latitude,
            longitude: longitude,
            rating: newRating,
            tags: tags,
            notes: notes,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: Date(),
            isVerified: isVerified,
            reportCount: reportCount,
            images: images,
            dogAmenities: dogAmenities,
            restaurantSeatingType: restaurantSeatingType
        )
    }
    
    func addingImage(_ imageUrl: String) -> Place {
        var newImages = images
        newImages.append(imageUrl)
        return Place(
            id: id,
            name: name,
            type: type,
            address: address,
            latitude: latitude,
            longitude: longitude,
            rating: rating,
            tags: tags,
            notes: notes,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: Date(),
            isVerified: isVerified,
            reportCount: reportCount,
            images: newImages,
            dogAmenities: dogAmenities,
            restaurantSeatingType: restaurantSeatingType
        )
    }
    
    func incrementingReportCount() -> Place {
        return Place(
            id: id,
            name: name,
            type: type,
            address: address,
            latitude: latitude,
            longitude: longitude,
            rating: rating,
            tags: tags,
            notes: notes,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: Date(),
            isVerified: isVerified,
            reportCount: reportCount + 1,
            images: images,
            dogAmenities: dogAmenities,
            restaurantSeatingType: restaurantSeatingType
        )
    }
    
    // MARK: - PlaceType Enum
    
    enum PlaceType: String, CaseIterable, Codable {
        case coffee = "coffee"
        case trail = "trail"
        case park = "park"
        case beach = "beach"
        case shop = "shop"
        case camp = "camp"
        case restaurant = "restaurant"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .coffee: return "Coffee"
            case .trail: return "Trail"
            case .park: return "Park"
            case .beach: return "Beach"
            case .shop: return "Shop"
            case .camp: return "Camp"
            case .restaurant: return "Restaurant"
            case .other: return "Other"
            }
        }
        
        var iconName: String {
            switch self {
            case .coffee: return "cup.and.saucer.fill"
            case .trail: return "figure.hiking"
            case .park: return "tree.fill"
            case .beach: return "beach.umbrella.fill"
            case .shop: return "bag.fill"
            case .camp: return "tent.fill"
            case .restaurant: return "fork.knife"
            case .other: return "mappin.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .coffee: return "orange"
            case .trail: return "green"
            case .park: return "blue"
            case .beach: return "cyan"
            case .shop: return "purple"
            case .camp: return "brown"
            case .restaurant: return "red"
            case .other: return "gray"
            }
        }
    }
    
    // MARK: - Restaurant Seating Type
    
    enum RestaurantSeatingType: String, CaseIterable, Codable {
        case indoor = "indoor"
        case outdoor = "outdoor"
        case heatedPatio = "heated_patio"
        
        var displayName: String {
            switch self {
            case .indoor: return "Indoor"
            case .outdoor: return "Outdoor"
            case .heatedPatio: return "Heated patio"
            }
        }
        
        var englishName: String {
            switch self {
            case .indoor: return "Indoor"
            case .outdoor: return "Outdoor"
            case .heatedPatio: return "Heated Patio"
            }
        }
        
        var iconName: String {
            switch self {
            case .indoor: return "house.fill"
            case .outdoor: return "sun.max.fill"
            case .heatedPatio: return "flame.fill"
            }
        }
    }
}

// MARK: - Place tags (UI labels)

extension Place {
    /// Human-readable text for a tag stored in Firestore (`camelCase`, `snake_case`, or known keys).
    static func displayLabel(forTag raw: String) -> String {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty { return raw }
        let known: [String: String] = [
            "offLeash": "Off-leash allowed",
            "dogFriendly": "Dog-friendly",
            "outdoorSeating": "Outdoor patio",
            "fenced": "Fenced area",
            "dogPark": "Dog park",
            "metroDetroit": "Metro Detroit",
            "needsReview": "Needs review",
            "troy": "Troy",
            "annArbor": "Ann Arbor",
            "birmingham": "Birmingham",
            "royalOak": "Royal Oak",
            "sterlingHeights": "Sterling Heights",
            "coffee": "Coffee shop",
            "park": "Park",
            "trail": "Trail",
            "restaurant": "Restaurant",
            "patio": "Patio",
            "indoorAccess": "Indoor friendly",
            "heatedPatio": "Heated patio",
            "inStore": "In-store friendly",
            "waterStation": "Water station",
            "wasteBags": "Waste bags"
        ]
        if let label = known[key] { return label }
        return humanizeTagKey(key)
    }
    
    private static func humanizeTagKey(_ key: String) -> String {
        var result = ""
        for ch in key {
            if ch.isUppercase, !result.isEmpty, let last = result.last, last.isLowercase {
                result.append(" ")
            }
            if ch == "_" {
                result.append(" ")
            } else {
                result.append(ch)
            }
        }
        let parts = result.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !parts.isEmpty else { return key.prefix(1).uppercased() + key.dropFirst() }
        return parts.map { p in p.prefix(1).uppercased() + p.dropFirst().lowercased() }.joined(separator: " ")
    }
}

// MARK: - Dog Amenities

struct DogAmenities: Codable, Equatable {
    var hasDogBowl: Bool
    var hasIndoorAccess: Bool
    var isOutdoorOnly: Bool
    var hasDogTreats: Bool
    var hasWaterStation: Bool
    var hasShade: Bool
    var hasFencedArea: Bool
    var allowsOffLeash: Bool
    var hasWasteBags: Bool
    var hasDogWash: Bool
    
    static let empty = DogAmenities(
        hasDogBowl: false,
        hasIndoorAccess: false,
        isOutdoorOnly: false,
        hasDogTreats: false,
        hasWaterStation: false,
        hasShade: false,
        hasFencedArea: false,
        allowsOffLeash: false,
        hasWasteBags: false,
        hasDogWash: false
    )
    
    var amenitiesList: [String] {
        var amenities: [String] = []
        if hasDogBowl { amenities.append("Dog Bowls") }
        if hasIndoorAccess { amenities.append("Indoor Access") }
        if hasDogTreats { amenities.append("Dog Treats") }
        if hasWaterStation { amenities.append("Water Station") }
        if hasShade { amenities.append("Shade") }
        if hasFencedArea { amenities.append("Fenced Area") }
        if allowsOffLeash { amenities.append("Off-Leash Allowed") }
        if hasWasteBags { amenities.append("Waste Bags") }
        if hasDogWash { amenities.append("Dog Wash") }
        return amenities
    }
}

// MARK: - Review Model

struct Review: Identifiable, Codable, Equatable {
    let id: String
    let placeId: String
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let images: [String] // Firebase Storage URLs
    let createdAt: Date
    let helpfulCount: Int
    let helpfulVoters: [String] // User IDs who found this helpful
    
    init(id: String = UUID().uuidString, placeId: String, userId: String, userName: String, rating: Int, comment: String, images: [String] = [], createdAt: Date = Date(), helpfulCount: Int = 0, helpfulVoters: [String] = []) {
        self.id = id
        self.placeId = placeId
        self.userId = userId
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.images = images
        self.createdAt = createdAt
        self.helpfulCount = helpfulCount
        self.helpfulVoters = helpfulVoters
    }
    
    func addingHelpfulVote(from userId: String) -> Review {
        var newVoters = helpfulVoters
        if !newVoters.contains(userId) {
            newVoters.append(userId)
        }
        return Review(
            id: id,
            placeId: placeId,
            userId: userId,
            userName: userName,
            rating: rating,
            comment: comment,
            images: images,
            createdAt: createdAt,
            helpfulCount: newVoters.count,
            helpfulVoters: newVoters
        )
    }
    
    func removingHelpfulVote(from userId: String) -> Review {
        let newVoters = helpfulVoters.filter { $0 != userId }
        return Review(
            id: id,
            placeId: placeId,
            userId: userId,
            userName: userName,
            rating: rating,
            comment: comment,
            images: images,
            createdAt: createdAt,
            helpfulCount: newVoters.count,
            helpfulVoters: newVoters
        )
    }
}

// MARK: - Place Report Model

struct PlaceReport: Identifiable, Codable, Equatable {
    let id: String
    let placeId: String
    let reporterId: String
    let reporterName: String
    let reason: ReportReason
    let description: String
    let createdAt: Date
    let isResolved: Bool
    
    init(id: String = UUID().uuidString, placeId: String, reporterId: String, reporterName: String, reason: ReportReason, description: String, createdAt: Date = Date(), isResolved: Bool = false) {
        self.id = id
        self.placeId = placeId
        self.reporterId = reporterId
        self.reporterName = reporterName
        self.reason = reason
        self.description = description
        self.createdAt = createdAt
        self.isResolved = isResolved
    }
    
    enum ReportReason: String, CaseIterable, Codable {
        case inaccurateInfo = "inaccurate_info"
        case notDogFriendly = "not_dog_friendly"
        case closed = "closed"
        case duplicate = "duplicate"
        case inappropriate = "inappropriate"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .inaccurateInfo: return "Inaccurate Information"
            case .notDogFriendly: return "Not Dog Friendly"
            case .closed: return "Place is Closed"
            case .duplicate: return "Duplicate Listing"
            case .inappropriate: return "Inappropriate Content"
            case .other: return "Other"
            }
        }
    }
}

// MARK: - Favorites Model

struct UserFavorites: Codable {
    let userId: String
    let placeIds: [String]
    let updatedAt: Date
    
    init(userId: String, placeIds: [String] = [], updatedAt: Date = Date()) {
        self.userId = userId
        self.placeIds = placeIds
        self.updatedAt = updatedAt
    }
    
    func addingPlace(_ placeId: String) -> UserFavorites {
        var newPlaceIds = placeIds
        if !newPlaceIds.contains(placeId) {
            newPlaceIds.append(placeId)
        }
        return UserFavorites(userId: userId, placeIds: newPlaceIds, updatedAt: Date())
    }
    
    func removingPlace(_ placeId: String) -> UserFavorites {
        let newPlaceIds = placeIds.filter { $0 != placeId }
        return UserFavorites(userId: userId, placeIds: newPlaceIds, updatedAt: Date())
    }
}

// MARK: - User Place Content

/// User-generated content for places (comments and photos)
struct UserPlaceContent: Identifiable, Codable, Equatable {
    let id: String
    let placeId: String
    let userId: String
    let userName: String
    let comment: String
    let imageURLs: [String]
    let likes: Int
    let likedBy: [String] // User IDs who liked this content
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String = UUID().uuidString, placeId: String, userId: String, userName: String, comment: String, imageURLs: [String] = [], likes: Int = 0, likedBy: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.placeId = placeId
        self.userId = userId
        self.userName = userName
        self.comment = comment
        self.imageURLs = imageURLs
        self.likes = likes
        self.likedBy = likedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - User Profile

/// User profile model for Firebase integration
struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let name: String
    let dogName: String
    let dogPhotoURL: String?
    let dogBirthday: Date?
    let dogBreed: String
    let dogWeight: Double
    let dogGender: String
    let dogTraits: [String]
    let dogNotes: String
    let profileImageURL: String?
    let favoritePlaceIDs: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties
    var dogAgeInYears: Int {
        guard let birthday = dogBirthday else { return 0 }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year ?? 0
    }
    
    var dogAgeInMonths: Int {
        guard let birthday = dogBirthday else { return 0 }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.month], from: birthday, to: Date())
        return ageComponents.month ?? 0
    }
    
    var dogAgeDescription: String {
        let years = dogAgeInYears
        let months = dogAgeInMonths
        
        if years > 0 {
            return "\(years) year\(years == 1 ? "" : "s") old"
        } else if months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") old"
        } else {
            return "Puppy"
        }
    }
    
    // Coding keys to exclude computed properties
    enum CodingKeys: String, CodingKey {
        case id, email, name, dogName, dogPhotoURL, dogBirthday, dogBreed, dogWeight
        case dogGender, dogTraits, dogNotes, profileImageURL, favoritePlaceIDs, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        dogName = try container.decodeIfPresent(String.self, forKey: .dogName) ?? ""
        dogPhotoURL = try container.decodeIfPresent(String.self, forKey: .dogPhotoURL)
        dogBirthday = try container.decodeIfPresent(Date.self, forKey: .dogBirthday)
        dogBreed = try container.decodeIfPresent(String.self, forKey: .dogBreed) ?? ""
        dogWeight = try container.decodeIfPresent(Double.self, forKey: .dogWeight) ?? 0.0
        dogGender = try container.decodeIfPresent(String.self, forKey: .dogGender) ?? ""
        dogTraits = try container.decodeIfPresent([String].self, forKey: .dogTraits) ?? []
        if let notes = try? container.decode(String.self, forKey: .dogNotes) {
            dogNotes = notes
        } else if let notesArray = try? container.decode([String].self, forKey: .dogNotes) {
            dogNotes = notesArray.joined(separator: ", ")
        } else {
            dogNotes = ""
        }
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        favoritePlaceIDs = try container.decodeIfPresent([String].self, forKey: .favoritePlaceIDs) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    init(id: String, email: String, name: String, dogName: String = "", dogPhotoURL: String? = nil, dogBirthday: Date? = nil, dogBreed: String = "", dogWeight: Double = 0.0, dogGender: String = "", dogTraits: [String] = [], dogNotes: String = "", profileImageURL: String? = nil, favoritePlaceIDs: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.dogName = dogName
        self.dogPhotoURL = dogPhotoURL
        self.dogBirthday = dogBirthday
        self.dogBreed = dogBreed
        self.dogWeight = dogWeight
        self.dogGender = dogGender
        self.dogTraits = dogTraits
        self.dogNotes = dogNotes
        self.profileImageURL = profileImageURL
        self.favoritePlaceIDs = favoritePlaceIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}