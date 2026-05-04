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
        // Image URLs verified via Wikipedia `pageimages` / direct HEAD where noted. Fallbacks = nearby landmarks / region.
        curatedPlaces = [
            CuratedPlace(
                id: "national-1",
                name: "Central Park",
                type: .park,
                address: "Central Park, New York, NY 10024",
                locationLabel: "New York, NY",
                latitude: 40.7829,
                longitude: -73.9654,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg/960px-Global_Citizen_Festival_Central_Park_New_York_City_from_NYonAir_%2815351915006%29.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Empire_State_Building_%28aerial_view%29.jpg/960px-Empire_State_Building_%28aerial_view%29.jpg",
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
                address: "501 Stanyan St, San Francisco, CA 94117",
                locationLabel: "San Francisco, CA",
                latitude: 37.7694,
                longitude: -122.4862,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Golden_Gate_Bridge_as_seen_from_Battery_East.jpg/960px-Golden_Gate_Bridge_as_seen_from_Battery_East.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/California-06241_-_In_front_of_museum_%2820449897948%29.jpg/960px-California-06241_-_In_front_of_museum_%2820449897948%29.jpg",
                description: "Massive urban park with designated off-leash areas, bison paddock views, and room to roam.",
                isNational: true,
                rating: 4.9,
                tags: ["Off-Leash Areas", "Scenic Views", "Large Space"],
                amenities: ["Off-Leash Areas", "Water Fountains", "Parking", "Restrooms"]
            ),
            CuratedPlace(
                id: "national-3",
                name: "Dog Beach Huntington Beach",
                type: .beach,
                address: "100 Goldenwest St, Huntington Beach, CA 92648",
                locationLabel: "Huntington Beach, CA",
                latitude: 33.6595,
                longitude: -117.9988,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Huntington_Beach_CA_USA_%28cropped%29.jpg/960px-Huntington_Beach_CA_USA_%28cropped%29.jpg",
                description: "Famous dog-friendly beach where pups can run in the sand and surf — a California classic.",
                isNational: true,
                rating: 4.7,
                tags: ["Off-Leash Beach", "Ocean Access", "Free Parking"],
                amenities: ["Off-Leash Beach", "Rinse Stations", "Parking", "Shade Areas"]
            ),
            CuratedPlace(
                id: "national-4",
                name: "Griffith Park",
                type: .park,
                address: "4730 Crystal Springs Dr, Los Angeles, CA 90027",
                locationLabel: "Los Angeles, CA",
                latitude: 34.1367,
                longitude: -118.2846,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Ferndell_griffith_park.jpg/960px-Ferndell_griffith_park.jpg",
                description: "One of the largest urban parks in the U.S., with miles of trails and the landmark observatory skyline.",
                isNational: true,
                rating: 4.6,
                tags: ["Hiking Trails", "Large Space", "Scenic Views"],
                amenities: ["Hiking Trails", "Water Stations", "Parking", "Picnic Areas"]
            ),
            CuratedPlace(
                id: "national-orion-oaks",
                name: "Orion Oaks Dog Park",
                type: .park,
                address: "2301 Joslyn Rd, Orion Township, MI 48360",
                locationLabel: "Orion Township, MI",
                latitude: 42.7858,
                longitude: -83.2844,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/2f/Downtownlakeorion.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Detroit_Skyline_%28Nov2021%29.jpg/960px-Detroit_Skyline_%28Nov2021%29.jpg",
                description: "Huge dog parks separated into several areas, trails, tables, and benches near Lake Orion.",
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
                locationLabel: "Durango, CO",
                latitude: 37.2753,
                longitude: -107.8801,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Durango%2C_Colorado.jpg/960px-Durango%2C_Colorado.jpg",
                description: "River access and wide open space with San Juan mountain views — great for adventurous pups.",
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
                locationLabel: "Park City, UT",
                latitude: 40.6461,
                longitude: -111.4980,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Park_City_overview.jpg/960px-Park_City_overview.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Salt_Lake_Union_Pacific_Railroad_Station%2C_South_Temple_at_400_West%2C_Central_City_West%2C_Salt_Lake_City%2C_UT%2C_USA.jpg/960px-Salt_Lake_Union_Pacific_Railroad_Station%2C_South_Temple_at_400_West%2C_Central_City_West%2C_Salt_Lake_City%2C_UT%2C_USA.jpg",
                description: "43-acre natural off-leash space near Olympic Park — room to roam in mountain air.",
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
                locationLabel: "Jenison, MI",
                latitude: 42.9075,
                longitude: -85.8064,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Jenison.jpg/960px-Jenison.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Detroit_Skyline_%28Nov2021%29.jpg/960px-Detroit_Skyline_%28Nov2021%29.jpg",
                description: "Separate areas for large and small dogs plus ravine trails — Grand Rapids area favorite.",
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
                locationLabel: "Woodbury, MN",
                latitude: 44.9231,
                longitude: -92.9592,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Woodbury_city_hall_%28new%29.jpg/960px-Woodbury_city_hall_%28new%29.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/James_J._Hill_House_2013.jpg/960px-James_J._Hill_House_2013.jpg",
                description: "Free off-leash dog park in the Twin Cities east metro with plenty of room to play.",
                isNational: true,
                rating: 4.5,
                tags: ["Free", "Off-Leash", "Socialization"],
                amenities: ["Free Entry", "Large Space", "Socialization Area", "Clean Facilities"]
            ),
            CuratedPlace(
                id: "national-birmingham-downtown",
                name: "Birmingham Downtown",
                type: .dogFriendlyDistrict,
                address: "Downtown Birmingham, Woodward Ave corridor, Birmingham, MI 48009",
                locationLabel: "Birmingham downtown, MI",
                latitude: 42.54667,
                longitude: -83.21139,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Downtown_Birmingham_MI_2025.jpg/960px-Downtown_Birmingham_MI_2025.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Detroit_Skyline_%28Nov2021%29.jpg/960px-Detroit_Skyline_%28Nov2021%29.jpg",
                description: "A very dog-friendly downtown strip: boutiques and clothing stores—including names like lululemon and Rag & Bone—often welcome on-leash dogs inside, patio cafés are set up for hanging out with your pup, and strolling Woodward with a leash in hand feels like the default. Store rules can still differ, so a quick peek at the door (or a short call) is smart before you walk in.",
                isNational: true,
                rating: 4.9,
                tags: ["Walkable core", "Retail-friendly", "Café patios"],
                amenities: ["Many shops open to leashed dogs", "Pet-friendly outdoor seating", "Strollable blocks"]
            ),
            
            // Nearby Favorites (Michigan-based places)
            CuratedPlace(
                id: "nearby-1",
                name: "Belle Isle Park",
                type: .park,
                address: "99 Pleasure Dr, Detroit, MI 48207",
                locationLabel: "Detroit, MI",
                latitude: 42.3369,
                longitude: -82.9636,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Belle_Isle_Aquarium_exterior.jpg/960px-Belle_Isle_Aquarium_exterior.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Detroit_Skyline_%28Nov2021%29.jpg/960px-Detroit_Skyline_%28Nov2021%29.jpg",
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
                address: "1900 Atwater St, Detroit, MI 48207",
                locationLabel: "Detroit, MI",
                latitude: 42.3344,
                longitude: -82.9847,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Detroit_Skyline_from_Windsor_2025-09-01.jpg/960px-Detroit_Skyline_from_Windsor_2025-09-01.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Detroit_Skyline_%28Nov2021%29.jpg/960px-Detroit_Skyline_%28Nov2021%29.jpg",
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
                locationLabel: "Metro Detroit, MI",
                latitude: 42.2464,
                longitude: -83.7417,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Detroit_Skyline_%28Nov2021%29.jpg/960px-Detroit_Skyline_%28Nov2021%29.jpg",
                fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Detroit_Skyline_from_Windsor_2025-09-01.jpg/960px-Detroit_Skyline_from_Windsor_2025-09-01.jpg",
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
                address: "1610 Washington Hts, Ann Arbor, MI 48104",
                locationLabel: "Ann Arbor, MI",
                latitude: 42.2756,
                longitude: -83.7319,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/NicholsArb.JPG/960px-NicholsArb.JPG",
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
                address: "1001 S Harbor Dr, Grand Haven, MI 49417",
                locationLabel: "Grand Haven, MI",
                latitude: 43.0631,
                longitude: -86.2284,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/5/5f/GrandHavenPierLight.jpg",
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
                address: "6748 S Dune Hwy, Empire, MI 49630",
                locationLabel: "Empire, MI",
                latitude: 44.8733,
                longitude: -86.0583,
                imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Sleeping_Bear_Dunes_Nat_Park_2024.jpg/960px-Sleeping_Bear_Dunes_Nat_Park_2024.jpg",
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
