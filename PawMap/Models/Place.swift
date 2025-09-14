import Foundation
import CoreLocation
import MapKit

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
    let userName: String
    let isAutoLoaded: Bool
    let verificationCount: Int
    let source: String?
    let reviews: [Review]
    let dogAmenities: DogAmenities
    let images: [String] // URLs or base64 encoded images
    let createdAt: Date
    let updatedAt: Date
    let reports: [PlaceReport] // Reports from users about inaccuracies
    let isVerified: Bool // Admin verification status
    
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
    
    enum PlaceType: String, CaseIterable, Codable {
        case coffee = "coffee"
        case trail = "trail"
        case park = "park"
        case beach = "beach"
        case shop = "shop"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .coffee: return "咖啡店"
            case .trail: return "步道"
            case .park: return "狗公园"
            case .beach: return "海滩"
            case .shop: return "商店/商场"
            case .other: return "其他"
            }
        }
        
        var iconName: String {
            switch self {
            case .coffee: return "cup.and.saucer.fill"
            case .trail: return "figure.hiking"
            case .park: return "leaf.fill"
            case .beach: return "beach.umbrella.fill"
            case .shop: return "bag.fill"
            case .other: return "mappin"
            }
        }
        
        var color: String {
            switch self {
            case .coffee: return "brown"
            case .trail: return "green"
            case .park: return "blue"
            case .beach: return "cyan"
            case .shop: return "purple"
            case .other: return "gray"
            }
        }
    }
}

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
}

struct Review: Identifiable, Codable, Equatable {
    let id = UUID()
    let user: String
    let rating: Int
    let comment: String
    let date: Date
    let userPhotos: [String] // Base64 encoded images from user
    let isHelpful: Int // Number of helpful votes
    let helpfulVoters: [String] // User IDs who found this helpful
}

struct DogMeetup: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let location: String
    let date: Date
    let time: String
    let dogBreed: String
    let notes: String
    let organizer: String
    let organizerId: String
    let attendees: [MeetupAttendee]
    let createdAt: Date
}

struct MeetupAttendee: Identifiable, Codable, Equatable {
    let id = UUID()
    let userId: String
    let name: String
    let dogBreed: String
    let notes: String
}

struct UserProfile: Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let dogBreed: String
    let dogName: String
    let profileImage: Data?
    let dogPhoto: Data?
}

struct PlaceReport: Identifiable, Codable, Equatable {
    let id = UUID()
    let placeId: String
    let reporterId: String
    let reporterName: String
    let reason: ReportReason
    let description: String
    let date: Date
    let isResolved: Bool
    
    enum ReportReason: String, CaseIterable, Codable {
        case inaccurateInfo = "inaccurate_info"
        case notDogFriendly = "not_dog_friendly"
        case closed = "closed"
        case duplicate = "duplicate"
        case inappropriate = "inappropriate"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .inaccurateInfo: return "信息不准确"
            case .notDogFriendly: return "不欢迎狗狗"
            case .closed: return "已关闭"
            case .duplicate: return "重复地点"
            case .inappropriate: return "内容不当"
            case .other: return "其他"
            }
        }
    }
}

// 扩展 CLLocationCoordinate2D 使其可编码
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}
