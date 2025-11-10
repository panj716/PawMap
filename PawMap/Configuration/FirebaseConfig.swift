import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

/// Configuration class for Firebase services
class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    /// Configure Firebase services
    func configure() {
        // Firebase is already configured via GoogleService-Info.plist
        // This method can be used for additional configuration if needed
        
        configureFirestore()
        configureAuth()
        configureStorage()
    }
    
    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        Firestore.firestore().settings = settings
    }
    
    private func configureAuth() {
        // Configure authentication settings
        Auth.auth().languageCode = "en"
    }
    
    private func configureStorage() {
        // Configure storage settings
        let storage = Storage.storage()
        // Additional storage configuration can be added here
    }
}

// MARK: - App Configuration

struct AppConfig {
    static let shared = AppConfig()
    
    // MARK: - App Information
    let appName = "PawMap"
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Firebase Collections
    struct Collections {
        static let places = "places"
        static let reviews = "reviews"
        static let users = "users"
        static let favorites = "favorites"
        static let curatedPlaces = "curatedPlaces"
        static let reports = "reports"
        static let userStats = "userStats"
        static let userPreferences = "userPreferences"
        static let admins = "admins"
    }
    
    // MARK: - Storage Paths
    struct StoragePaths {
        static let userProfiles = "users"
        static let placeImages = "places"
        static let reviewImages = "reviews"
        static let curatedPlaceImages = "curatedPlaces"
    }
    
    // MARK: - Limits and Constraints
    struct Limits {
        static let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB
        static let maxImagesPerPlace = 10
        static let maxImagesPerReview = 5
        static let maxReviewLength = 1000
        static let maxPlaceNameLength = 100
        static let maxPlaceNotesLength = 2000
        static let maxTagsPerPlace = 10
        static let maxFavoritesPerUser = 1000
    }
    
    // MARK: - Cache Settings
    struct Cache {
        static let imageCacheSize = 100 // Maximum images in memory
        static let imageCacheMemoryLimit = 50 * 1024 * 1024 // 50MB
        static let cacheExpirationDays = 7
    }
    
    // MARK: - Location Settings
    struct Location {
        static let defaultLatitude = 42.2464
        static let defaultLongitude = -83.7417
        static let defaultSpan = 0.1
        static let nearbyRadiusKm = 30.0
        static let maxSearchRadiusKm = 100.0
    }
    
    // MARK: - UI Settings
    struct UI {
        static let animationDuration: Double = 0.3
        static let debounceDelay: Double = 0.3
        static let imageCornerRadius: CGFloat = 8
        static let cardCornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 8
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableOfflineMode = true
        static let enablePushNotifications = true
        static let enableAnalytics = true
        static let enableCrashlytics = true
        static let enableTopPicks = true
        static let enableUserReviews = true
        static let enablePlaceReporting = true
        static let enableSocialFeatures = false // Future feature
    }
    
    // MARK: - API Keys (for future use)
    struct APIKeys {
        // Add any third-party API keys here
        // static let googleMapsAPIKey = "your_key_here"
        // static let weatherAPIKey = "your_key_here"
    }
    
    // MARK: - Environment
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    // MARK: - Debug Settings
    struct Debug {
        static let enableLogging = Environment.current == .development
        static let enableVerboseLogging = Environment.current == .development
        static let enablePerformanceMonitoring = Environment.current == .development
    }
}

// MARK: - Error Handling

enum PawMapError: LocalizedError {
    case networkError
    case authenticationRequired
    case invalidData
    case imageUploadFailed
    case placeNotFound
    case reviewNotFound
    case userNotFound
    case permissionDenied
    case rateLimitExceeded
    case storageQuotaExceeded
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .authenticationRequired:
            return "Please sign in to continue."
        case .invalidData:
            return "Invalid data format received."
        case .imageUploadFailed:
            return "Failed to upload image. Please try again."
        case .placeNotFound:
            return "Place not found."
        case .reviewNotFound:
            return "Review not found."
        case .userNotFound:
            return "User not found."
        case .permissionDenied:
            return "Permission denied."
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .storageQuotaExceeded:
            return "Storage quota exceeded."
        case .unknown:
            return "An unknown error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .authenticationRequired:
            return "Sign in to your account to continue."
        case .imageUploadFailed:
            return "Try uploading a smaller image or check your connection."
        case .rateLimitExceeded:
            return "Wait a few minutes before trying again."
        case .storageQuotaExceeded:
            return "Delete some old images to free up space."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

