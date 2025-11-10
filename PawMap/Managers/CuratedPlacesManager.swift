import Foundation
import CoreLocation

class CuratedPlacesManager: ObservableObject {
    static let shared = CuratedPlacesManager()
    
    @Published var curatedPlaces: [CuratedPlace] = []
    @Published var userLocation: CLLocation?
    
    private init() {
        loadCuratedPlaces()
    }
    
    // MARK: - Sample Curated Places Data
    private func loadCuratedPlaces() {
        curatedPlaces = [
            // National Favorites (Iconic places across the US)
            CuratedPlace(
                id: "national-1",
                name: "Central Park",
                type: .park,
                address: "New York, NY 10024",
                latitude: 40.7829,
                longitude: -73.9654,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "Iconic park with dedicated dog runs and beautiful walking trails. A must-visit for any dog lover in NYC.",
                isNational: true,
                rating: 4.8,
                tags: ["Off-Leash Areas", "Water Fountains", "Dog Runs"],
                amenities: ["Multiple Dog Runs", "Water Stations", "Waste Bags", "Benches"]
            ),
            
            CuratedPlace(
                id: "national-2",
                name: "Golden Gate Park",
                type: .park,
                address: "San Francisco, CA 94117",
                latitude: 37.7694,
                longitude: -122.4862,
                imageURL: "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800",
                description: "Massive urban park with designated off-leash areas and scenic views of the Golden Gate Bridge.",
                isNational: true,
                rating: 4.9,
                tags: ["Off-Leash Areas", "Scenic Views", "Large Space"],
                amenities: ["Off-Leash Areas", "Water Fountains", "Parking", "Restrooms"]
            ),
            
            CuratedPlace(
                id: "national-3",
                name: "Dog Beach Huntington Beach",
                type: .beach,
                address: "Huntington Beach, CA 92648",
                latitude: 33.6595,
                longitude: -117.9988,
                imageURL: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800",
                description: "Famous dog-friendly beach where pups can run free in the sand and surf. A California classic!",
                isNational: true,
                rating: 4.7,
                tags: ["Off-Leash Beach", "Ocean Access", "Free Parking"],
                amenities: ["Off-Leash Beach", "Rinse Stations", "Parking", "Shade Areas"]
            ),
            
            CuratedPlace(
                id: "national-4",
                name: "Griffith Park",
                type: .park,
                address: "Los Angeles, CA 90027",
                latitude: 34.1367,
                longitude: -118.2846,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "One of the largest urban parks in America with miles of hiking trails perfect for adventurous dogs.",
                isNational: true,
                rating: 4.6,
                tags: ["Hiking Trails", "Large Space", "Scenic Views"],
                amenities: ["Hiking Trails", "Water Stations", "Parking", "Picnic Areas"]
            ),
            
            // New National Dog Parks
            CuratedPlace(
                id: "national-orion-oaks",
                name: "Orion Oaks Dog Park",
                type: .park,
                address: "2301 Joslyn Rd, Orion Township, MI 48360",
                latitude: 42.7858,
                longitude: -83.2844,
                imageURL: "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=800&h=400&fit=crop",
                description: "Huge dog parks separated into 4 areas. Trails in the dog park are nice, many tables and benches to sit.",
                isNational: true,
                rating: 4.8,
                tags: ["Off-Leash", "Multiple Areas", "Trails"],
                amenities: ["4 Separate Areas", "Walking Trails", "Benches", "Water Stations"]
            ),
            
            CuratedPlace(
                id: "national-durango",
                name: "Durango Off-Leash Area",
                type: .park,
                address: "US-160 & Hwy 550, Durango, CO 81301",
                latitude: 37.2753,
                longitude: -107.8801,
                imageURL: "https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800&h=400&fit=crop",
                description: "There's river access and plenty of space to just walk while the pups run.",
                isNational: true,
                rating: 4.7,
                tags: ["River Access", "Mountain Views", "Off-Leash"],
                amenities: ["River Access", "Mountain Setting", "Large Space", "Natural Terrain"]
            ),
            
            CuratedPlace(
                id: "national-run-a-muk",
                name: "Run-a-Muk Off-Leash Area",
                type: .park,
                address: "2387 Olympic Pkwy, Park City, UT 84098",
                latitude: 40.6461,
                longitude: -111.4980,
                imageURL: "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=800&h=400&fit=crop",
                description: "43 acre open space for pups to explore nature.",
                isNational: true,
                rating: 4.9,
                tags: ["43 Acres", "Nature Exploration", "Off-Leash"],
                amenities: ["43 Acre Space", "Natural Terrain", "Mountain Views", "Hiking Trails"]
            ),
            
            CuratedPlace(
                id: "national-grand-ravines",
                name: "Grand Ravines Dog Park",
                type: .park,
                address: "3991 Fillmore St, Jenison, MI 49428",
                latitude: 42.9075,
                longitude: -85.8064,
                imageURL: "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=800&h=400&fit=crop",
                description: "Areas for large and small dogs as well as trails for on-leash and off-leash exploration.",
                isNational: true,
                rating: 4.6,
                tags: ["Size Separation", "Trails", "Off-Leash"],
                amenities: ["Large/Small Dog Areas", "Walking Trails", "On/Off-Leash Areas", "Water Stations"]
            ),
            
            CuratedPlace(
                id: "national-andys-bark",
                name: "Andy's Bark Park",
                type: .park,
                address: "11664 Dale Rd, Woodbury, MN 55129",
                latitude: 44.9231,
                longitude: -92.9592,
                imageURL: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=800&h=400&fit=crop",
                description: "Free off-leash dog park with plenty of space for dogs to play and socialize.",
                isNational: true,
                rating: 4.5,
                tags: ["Free", "Off-Leash", "Socialization"],
                amenities: ["Free Entry", "Large Space", "Socialization Area", "Clean Facilities"]
            ),
            
            // Nearby Favorites (Michigan-based places)
            CuratedPlace(
                id: "nearby-1",
                name: "Belle Isle Park",
                type: .park,
                address: "Detroit, MI 48207",
                latitude: 42.3369,
                longitude: -82.9636,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "Beautiful island park in Detroit with dog-friendly areas and stunning river views.",
                isNational: false,
                rating: 4.5,
                tags: ["River Views", "Off-Leash Areas", "Walking Trails"],
                amenities: ["Off-Leash Areas", "Walking Trails", "Water Access", "Parking"]
            ),
            
            CuratedPlace(
                id: "nearby-2",
                name: "Milliken State Park",
                type: .park,
                address: "Detroit, MI 48207",
                latitude: 42.3344,
                longitude: -82.9847,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "Urban state park with waterfront trails perfect for dogs who love to explore.",
                isNational: false,
                rating: 4.3,
                tags: ["Waterfront", "Walking Trails", "Urban Park"],
                amenities: ["Walking Trails", "Water Access", "Parking", "Benches"]
            ),
            
            CuratedPlace(
                id: "nearby-3",
                name: "Huron-Clinton Metroparks",
                type: .park,
                address: "Metro Detroit Area, MI",
                latitude: 42.2464,
                longitude: -83.7417,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "Extensive park system with multiple dog-friendly locations throughout Metro Detroit.",
                isNational: false,
                rating: 4.4,
                tags: ["Multiple Locations", "Trails", "Water Access"],
                amenities: ["Multiple Parks", "Walking Trails", "Water Access", "Parking"]
            ),
            
            CuratedPlace(
                id: "nearby-4",
                name: "Nichols Arboretum",
                type: .park,
                address: "Ann Arbor, MI 48109",
                latitude: 42.2756,
                longitude: -83.7319,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "University of Michigan's beautiful arboretum with leashed dog access and peaceful trails.",
                isNational: false,
                rating: 4.6,
                tags: ["University Campus", "Walking Trails", "Leashed Dogs"],
                amenities: ["Walking Trails", "Natural Areas", "Parking", "Benches"]
            ),
            
            CuratedPlace(
                id: "nearby-5",
                name: "Grand Haven State Park",
                type: .beach,
                address: "Grand Haven, MI 49417",
                latitude: 43.0631,
                longitude: -86.2284,
                imageURL: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800",
                description: "Beautiful Lake Michigan beach with dog-friendly areas and stunning sunset views.",
                isNational: false,
                rating: 4.7,
                tags: ["Lake Michigan", "Beach Access", "Sunset Views"],
                amenities: ["Beach Access", "Parking", "Restrooms", "Picnic Areas"]
            ),
            
            CuratedPlace(
                id: "nearby-6",
                name: "Sleeping Bear Dunes",
                type: .park,
                address: "Empire, MI 49630",
                latitude: 44.8733,
                longitude: -86.0583,
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
                description: "National Lakeshore with dog-friendly trails and breathtaking views of Lake Michigan.",
                isNational: false,
                rating: 4.8,
                tags: ["National Park", "Lake Views", "Hiking Trails"],
                amenities: ["Hiking Trails", "Lake Access", "Parking", "Visitor Center"]
            )
        ]
    }
    
    // MARK: - Filtering Methods
    
    /// Get nearby favorites within specified radius
    func getNearbyFavorites(radiusMiles: Double = 30.0) -> [CuratedPlace] {
        guard let userLocation = userLocation else {
            // If no user location, return empty array
            return []
        }
        
        return curatedPlaces
            .filter { !$0.isNational && $0.isWithinRadius(radiusMiles, from: userLocation) }
            .sorted { $0.distance(from: userLocation) < $1.distance(from: userLocation) }
    }
    
    /// Get national favorites (with deduplication)
    func getNationalFavorites() -> [CuratedPlace] {
        var seenIds = Set<String>()
        var seenNames = Set<String>()
        
        return curatedPlaces
            .filter { $0.isNational }
            .filter { place in
                // Remove duplicates by ID
                guard !seenIds.contains(place.id) else { return false }
                seenIds.insert(place.id)
                
                // Remove duplicates by name (case-insensitive)
                let normalizedName = place.name.lowercased().trimmingCharacters(in: .whitespaces)
                guard !seenNames.contains(normalizedName) else { return false }
                seenNames.insert(normalizedName)
                
                return true
            }
            .sorted { $0.rating > $1.rating } // Sort by rating descending
    }
    
    /// Update user location
    func updateUserLocation(_ location: CLLocation) {
        userLocation = location
    }
    
    /// Get all curated places
    func getAllCuratedPlaces() -> [CuratedPlace] {
        return curatedPlaces
    }
}
