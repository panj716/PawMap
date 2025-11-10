import Foundation
import FirebaseFirestore
import FirebaseAuth

/// User model for Firebase integration
struct PawMapUser: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let name: String
    let profileImageUrl: String?
    let dogName: String?
    let dogBreed: String?
    let dogBirthday: Date?
    let dogWeight: Double?
    let dogGender: String?
    let dogTraits: [String]
    let dogNotes: String?
    let favoritePlaceIDs: [String]
    let createdAt: Date
    let lastActiveAt: Date
    
    // Computed properties
    var dogAgeInYears: Int? {
        guard let birthday = dogBirthday else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year
    }
    
    var dogAgeInMonths: Int? {
        guard let birthday = dogBirthday else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.month], from: birthday, to: Date())
        return ageComponents.month
    }
    
    var dogAgeDescription: String {
        guard let birthday = dogBirthday else { return "Age not specified" }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year, .month], from: birthday, to: Date())
        
        if let years = ageComponents.year, years > 0 {
            if let months = ageComponents.month, months > 0 {
                return "\(years) year\(years == 1 ? "" : "s"), \(months) month\(months == 1 ? "" : "s")"
            } else {
                return "\(years) year\(years == 1 ? "" : "s")"
            }
        } else if let months = ageComponents.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else {
            return "Less than 1 month"
        }
    }
    
    var displayName: String {
        return name.isEmpty ? "Anonymous User" : name
    }
    
    var hasDogProfile: Bool {
        return dogName != nil && !dogName!.isEmpty
    }
    
    // Coding keys to exclude computed properties
    enum CodingKeys: String, CodingKey {
        case id, email, name, profileImageUrl
        case dogName, dogBreed, dogBirthday, dogWeight, dogGender, dogTraits, dogNotes, favoritePlaceIDs
        case createdAt, lastActiveAt
    }
    
    // MARK: - Initializers
    
    init(id: String, email: String, name: String, profileImageUrl: String? = nil, dogName: String? = nil, dogBreed: String? = nil, dogBirthday: Date? = nil, dogWeight: Double? = nil, dogGender: String? = nil, dogTraits: [String] = [], dogNotes: String? = nil, favoritePlaceIDs: [String] = [], createdAt: Date = Date(), lastActiveAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.dogName = dogName
        self.dogBreed = dogBreed
        self.dogBirthday = dogBirthday
        self.dogWeight = dogWeight
        self.dogGender = dogGender
        self.dogTraits = dogTraits
        self.dogNotes = dogNotes
        self.favoritePlaceIDs = favoritePlaceIDs
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
    
    // MARK: - Update Methods
    
    func updatingProfileImage(_ url: String) -> PawMapUser {
        return PawMapUser(
            id: id,
            email: email,
            name: name,
            profileImageUrl: url,
            dogName: dogName,
            dogBreed: dogBreed,
            dogBirthday: dogBirthday,
            dogWeight: dogWeight,
            dogGender: dogGender,
            dogTraits: dogTraits,
            dogNotes: dogNotes,
            favoritePlaceIDs: favoritePlaceIDs,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt
        )
    }
    
    func updatingDogProfile(name: String? = nil, breed: String? = nil, birthday: Date? = nil, weight: Double? = nil, gender: String? = nil, traits: [String]? = nil, notes: String? = nil) -> PawMapUser {
        return PawMapUser(
            id: id,
            email: email,
            name: name ?? self.name,
            profileImageUrl: profileImageUrl,
            dogName: name ?? dogName,
            dogBreed: breed ?? dogBreed,
            dogBirthday: birthday ?? dogBirthday,
            dogWeight: weight ?? dogWeight,
            dogGender: gender ?? dogGender,
            dogTraits: traits ?? dogTraits,
            dogNotes: notes ?? dogNotes,
            favoritePlaceIDs: favoritePlaceIDs,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt
        )
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    let userId: String
    let favoritePlaceTypes: [Place.PlaceType]
    let notificationSettings: NotificationSettings
    let privacySettings: PrivacySettings
    let updatedAt: Date
    
    init(userId: String, favoritePlaceTypes: [Place.PlaceType] = [], notificationSettings: NotificationSettings = NotificationSettings(), privacySettings: PrivacySettings = PrivacySettings(), updatedAt: Date = Date()) {
        self.userId = userId
        self.favoritePlaceTypes = favoritePlaceTypes
        self.notificationSettings = notificationSettings
        self.privacySettings = privacySettings
        self.updatedAt = updatedAt
    }
}

struct NotificationSettings: Codable {
    let newPlacesNearby: Bool
    let newReviewsOnFavorites: Bool
    let weeklyDigest: Bool
    let marketingEmails: Bool
    
    init(newPlacesNearby: Bool = true, newReviewsOnFavorites: Bool = true, weeklyDigest: Bool = false, marketingEmails: Bool = false) {
        self.newPlacesNearby = newPlacesNearby
        self.newReviewsOnFavorites = newReviewsOnFavorites
        self.weeklyDigest = weeklyDigest
        self.marketingEmails = marketingEmails
    }
}

struct PrivacySettings: Codable {
    let profileVisibility: ProfileVisibility
    let showLocationInReviews: Bool
    let allowFriendRequests: Bool
    
    init(profileVisibility: ProfileVisibility = .public, showLocationInReviews: Bool = true, allowFriendRequests: Bool = true) {
        self.profileVisibility = profileVisibility
        self.showLocationInReviews = showLocationInReviews
        self.allowFriendRequests = allowFriendRequests
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .friends: return "Friends Only"
        case .private: return "Private"
        }
    }
}

// MARK: - User Statistics

struct UserStats: Codable {
    let userId: String
    let placesAdded: Int
    let reviewsWritten: Int
    let photosUploaded: Int
    let helpfulVotesReceived: Int
    let lastUpdated: Date
    
    init(userId: String, placesAdded: Int = 0, reviewsWritten: Int = 0, photosUploaded: Int = 0, helpfulVotesReceived: Int = 0, lastUpdated: Date = Date()) {
        self.userId = userId
        self.placesAdded = placesAdded
        self.reviewsWritten = reviewsWritten
        self.photosUploaded = photosUploaded
        self.helpfulVotesReceived = helpfulVotesReceived
        self.lastUpdated = lastUpdated
    }
}
