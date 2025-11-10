import Foundation
import CoreLocation
import MapKit

// MARK: - Curated Place Model
struct CuratedPlace: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let type: PlaceType
    let address: String
    let latitude: Double
    let longitude: Double
    let imageURL: String
    let description: String
    let isNational: Bool // true for National Favorites, false for Nearby Favorites
    let rating: Double
    let tags: [String]
    let amenities: [String]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
        case other = "Other"
        
        var iconName: String {
            switch self {
            case .park: return "tree.fill"
            case .cafe: return "cup.and.saucer.fill"
            case .beach: return "umbrella.beach.fill"
            case .trail: return "figure.hiking"
            case .camp: return "tent.fill"
            case .restaurant: return "fork.knife"
            case .shop: return "bag.fill"
            case .hotel: return "bed.double.fill"
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
            case .other: return "gray"
            }
        }
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

