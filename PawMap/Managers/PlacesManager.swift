import Foundation
import CoreLocation
import MapKit
import Combine

class PlacesManager: ObservableObject {
    @Published var places: [Place] = []
    @Published var filteredPlaces: [Place] = []
    @Published var isLoading = false
    @Published var selectedPlace: Place?
    
    private let userDefaults = UserDefaults.standard
    private let placesKey = "savedPlaces"
    
    init() {
        // Force clear any cached data to ensure we get the latest places
        userDefaults.removeObject(forKey: placesKey)
        loadPlaces()
        // Always load sample data to ensure we have the latest places
            loadSampleData()
    }
    
    func loadSampleData() {
        let samplePlaces = [
            // 密歇根海滩
            Place(
                id: "beach_1",
                name: "Grand Haven State Park Beach",
                type: .beach,
                address: "Grand Haven State Park Beach, Grand Haven, MI",
                latitude: 43.0631,
                longitude: -86.2284,
                rating: 4.9,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "This popular beach along Lake Michigan allows dogs on-leash from October 1 through April 30. The beach features beautiful sand dunes and stunning sunset views.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 25,
                source: "michigan_org_website",
                reviews: [
                    Review(
                        user: "Sarah M.",
                        rating: 5,
                        comment: "Beautiful beach! My dog loved running in the sand. Perfect for sunset walks.",
                        date: Date().addingTimeInterval(-86400 * 3),
                        userPhotos: [],
                        isHelpful: 8,
                        helpfulVoters: []
                    ),
                    Review(
                        user: "Mike D.",
                        rating: 4,
                        comment: "Great spot but dogs only allowed certain months. Check the rules before visiting.",
                        date: Date().addingTimeInterval(-86400 * 7),
                        userPhotos: [],
                        isHelpful: 5,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [
                    "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&h=600&fit=crop"
                ],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_2",
                name: "Holland State Park Beach",
                type: .beach,
                address: "Holland State Park Beach, Holland, MI",
                latitude: 42.7731,
                longitude: -86.2139,
                rating: 4.8,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on-leash at this Lake Michigan beach from October 1 through April 30. The beach offers pristine sand and clear waters.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 20,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_3",
                name: "Sleeping Bear Dunes National Lakeshore",
                type: .beach,
                address: "Sleeping Bear Dunes National Lakeshore, Empire, MI",
                latitude: 44.8667,
                longitude: -86.0333,
                rating: 4.9,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on-leash at designated areas of this stunning national lakeshore. Features include towering sand dunes and Lake Michigan views.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 30,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_4",
                name: "Pictured Rocks National Lakeshore",
                type: .beach,
                address: "Pictured Rocks National Lakeshore, Munising, MI",
                latitude: 46.6667,
                longitude: -86.1667,
                rating: 4.9,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "Dogs are permitted on-leash at designated areas of this Lake Superior shoreline. Features stunning rock formations and waterfalls.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 28,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            // 咖啡店
            Place(
                id: "coffee_1",
                name: "Atomic Coffee",
                type: .coffee,
                address: "Atomic Coffee, Royal Oak, MI",
                latitude: 42.4895,
                longitude: -83.1446,
                rating: 4.8,
                tags: ["waterBowl", "patio", "dogMenu"],
                notes: "Coffee & Bark - A dog-friendly coffee shop in Royal Oak where you can enjoy great coffee with your furry friend. Features outdoor seating and dog treats.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 15,
                source: "local_business",
                reviews: [
                    Review(
                        user: "Emma L.",
                        rating: 5,
                        comment: "Amazing coffee and my dog got free treats! The outdoor patio is perfect for dog owners.",
                        date: Date().addingTimeInterval(-86400 * 2),
                        userPhotos: [],
                        isHelpful: 12,
                        helpfulVoters: []
                    ),
                    Review(
                        user: "David K.",
                        rating: 4,
                        comment: "Great atmosphere, friendly staff. Dog water bowls available outside.",
                        date: Date().addingTimeInterval(-86400 * 5),
                        userPhotos: [],
                        isHelpful: 7,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: true,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [
                    "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&h=600&fit=crop"
                ],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "coffee_2",
                name: "Coffee and Bark",
                type: .coffee,
                address: "2733 Coolidge Hwy, Berkley, MI 48072",
                latitude: 42.5031,
                longitude: -83.1836,
                rating: 4.7,
                tags: ["dogMenu", "indoorAllowed"],
                notes: "Dog-friendly coffee shop with indoor seating allowed. Features a special dog menu for your furry companions.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 12,
                source: "local_business",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: true,
                    isOutdoorOnly: false,
                    hasDogTreats: true,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "coffee_3",
                name: "The Fern",
                type: .coffee,
                address: "406 E 4th St, Royal Oak, MI 48067",
                latitude: 42.4874,
                longitude: -83.1446,
                rating: 4.6,
                tags: ["indoorAllowed", "patio", "waterBowl"],
                notes: "Cozy coffee shop with indoor seating allowed, outdoor patio, and dog bowls available for your pets.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 10,
                source: "local_business",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: true,
                    isOutdoorOnly: false,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            // 原有的公园
            Place(
                id: "1",
                name: "Belle Isle Park",
                type: .park,
                address: "Belle Isle, Detroit, MI",
                latitude: 42.3389,
                longitude: -82.9967,
                rating: 4.5,
                tags: ["户外", "大空间", "水边"],
                notes: "美丽的岛屿公园，有专门的狗狗区域",
                userName: "系统",
                isAutoLoaded: true,
                verificationCount: 15,
                source: "互联网",
                reviews: [
                    Review(user: "张三", rating: 5, comment: "很棒的地方，我的狗很喜欢！", date: Date(), userPhotos: [], isHelpful: 3, helpfulVoters: []),
                    Review(user: "李四", rating: 4, comment: "环境很好，就是周末人比较多", date: Date(), userPhotos: [], isHelpful: 1, helpfulVoters: [])
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: true,
                    allowsOffLeash: true,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            // 更多海滩
            Place(
                id: "beach_5",
                name: "Muskegon State Park Beach",
                type: .beach,
                address: "Muskegon State Park Beach, Muskegon, MI",
                latitude: 43.2342,
                longitude: -86.2484,
                rating: 4.7,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "This Lake Michigan beach allows dogs on-leash during the off-season. Features include hiking trails and beautiful shoreline views.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 18,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_6",
                name: "Ludington State Park Beach",
                type: .beach,
                address: "Ludington State Park Beach, Ludington, MI",
                latitude: 44.0375,
                longitude: -86.4667,
                rating: 4.8,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "Dogs are permitted on-leash at this Lake Michigan beach during the off-season. The park also features hiking trails and camping areas.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 22,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_7",
                name: "Petoskey State Park Beach",
                type: .beach,
                address: "Petoskey State Park Beach, Petoskey, MI",
                latitude: 45.3733,
                longitude: -84.9553,
                rating: 4.7,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "This Lake Michigan beach allows dogs on-leash during the off-season. Known for its Petoskey stones and clear waters.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 16,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_8",
                name: "Tawas Point State Park Beach",
                type: .beach,
                address: "Tawas Point State Park Beach, East Tawas, MI",
                latitude: 44.2667,
                longitude: -83.4667,
                rating: 4.6,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on-leash at this Lake Huron beach during the off-season. Features include a lighthouse and bird watching opportunities.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 14,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_9",
                name: "Belle Isle Park Beach",
                type: .beach,
                address: "Belle Isle Park Beach, Detroit, MI",
                latitude: 42.3389,
                longitude: -82.9878,
                rating: 4.5,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "This Detroit River beach allows dogs on-leash. The park features walking trails, picnic areas, and beautiful city skyline views.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 12,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_10",
                name: "Huron-Clinton Metroparks - Kensington",
                type: .beach,
                address: "Huron-Clinton Metroparks - Kensington, Milford, MI",
                latitude: 42.5333,
                longitude: -83.6333,
                rating: 4.6,
                tags: ["onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on-leash at designated areas of this metro park. Features include a beach, hiking trails, and wildlife viewing.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 13,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            // Additional Michigan Dog-Friendly Beaches from michigan.org
            Place(
                id: "beach_11",
                name: "Ludington State Park Beach",
                type: .beach,
                address: "8800 W M-116, Ludington, MI 49431",
                latitude: 44.0375,
                longitude: -86.4668,
                rating: 4.9,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on leashes at this stunning beach. The park offers miles of shoreline along Lake Michigan with beautiful dunes and hiking trails.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 25,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_12",
                name: "Warren Dunes State Park",
                type: .beach,
                address: "12032 Red Arrow Hwy, Sawyer, MI 49125",
                latitude: 41.9075,
                longitude: -86.5958,
                rating: 4.8,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on leashes at this popular beach. The park features towering sand dunes and beautiful Lake Michigan shoreline.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 22,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_13",
                name: "Silver Lake State Park",
                type: .beach,
                address: "9679 W State Park Rd, Mears, MI 49436",
                latitude: 43.6689,
                longitude: -86.5389,
                rating: 4.7,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are allowed on leashes at this beautiful beach. The area offers stunning views of Lake Michigan and the Silver Lake Sand Dunes.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 20,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_14",
                name: "Muskegon State Park",
                type: .beach,
                address: "3560 Memorial Dr, North Muskegon, MI 49445",
                latitude: 43.2747,
                longitude: -86.3489,
                rating: 4.8,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on leashes at this Lake Michigan beach. The park features beautiful shoreline and excellent facilities.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 18,
                source: "michigan_org_website",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "2",
                name: "Grand Rapids Dog Park",
                type: .park,
                address: "Grand Rapids, MI",
                latitude: 42.9634,
                longitude: -85.6681,
                rating: 4.2,
                tags: ["围栏", "分离区域", "饮水站"],
                notes: "设施完善的狗狗公园",
                userName: "系统",
                isAutoLoaded: true,
                verificationCount: 8,
                source: "互联网",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: true,
                    allowsOffLeash: true,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "3",
                name: "Sleeping Bear Dunes",
                type: .beach,
                address: "Empire, MI",
                latitude: 44.8736,
                longitude: -86.0544,
                rating: 4.8,
                tags: ["海滩", "远足", "风景"],
                notes: "允许狗狗的海滩，风景绝美",
                userName: "系统",
                isAutoLoaded: true,
                verificationCount: 12,
                source: "互联网",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: false,
                    hasShade: false,
                    hasFencedArea: false,
                    allowsOffLeash: true,
                    hasWasteBags: false,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "4",
                name: "Madcap Coffee",
                type: .coffee,
                address: "Grand Rapids, MI",
                latitude: 42.9634,
                longitude: -85.6681,
                rating: 4.3,
                tags: ["露台", "室内允许"],
                notes: "欢迎狗狗的咖啡店，有户外座位",
                userName: "系统",
                isAutoLoaded: true,
                verificationCount: 6,
                source: "互联网",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: true,
                    isOutdoorOnly: false,
                    hasDogTreats: true,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "5",
                name: "Nordhouse Dunes",
                type: .trail,
                address: "Ludington, MI",
                latitude: 44.0331,
                longitude: -86.5192,
                rating: 4.6,
                tags: ["步道", "海滩", "露营"],
                notes: "允许狗狗的步道和海滩",
                userName: "系统",
                isAutoLoaded: true,
                verificationCount: 9,
                source: "互联网",
                reviews: [],
                dogAmenities: DogAmenities(
                    hasDogBowl: false,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: false,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: true,
                    hasWasteBags: false,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            
            // Additional Michigan Dog-Friendly Beaches
            Place(
                id: "beach_pictured_rocks",
                name: "Pictured Rocks National Lakeshore",
                type: .beach,
                address: "N8391 Sand Point Rd, Munising, MI 49862",
                latitude: 46.6701,
                longitude: -86.1992,
                rating: 4.8,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on most trails and beaches. The area features stunning sandstone cliffs and crystal clear Lake Superior waters.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 0,
                source: "internet_search",
                reviews: [
                    Review(
                        user: "Jennifer L.",
                        rating: 5,
                        comment: "Absolutely breathtaking! My dog loved exploring the trails. The views are incredible.",
                        date: Date().addingTimeInterval(-86400 * 5),
                        userPhotos: [],
                        isHelpful: 12,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_tawas_point",
                name: "Tawas Point State Park",
                type: .beach,
                address: "686 Tawas Beach Rd, East Tawas, MI 48730",
                latitude: 44.2569,
                longitude: -83.4547,
                rating: 4.7,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "This beautiful beach on Lake Huron welcomes leashed dogs. The area is known for its lighthouse and excellent bird watching.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 0,
                source: "internet_search",
                reviews: [
                    Review(
                        user: "Robert K.",
                        rating: 4,
                        comment: "Great beach for dogs! The lighthouse is beautiful and my dog enjoyed the water.",
                        date: Date().addingTimeInterval(-86400 * 8),
                        userPhotos: [],
                        isHelpful: 9,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_warren_dunes",
                name: "Warren Dunes State Park",
                type: .beach,
                address: "12032 Red Arrow Hwy, Sawyer, MI 49125",
                latitude: 41.9075,
                longitude: -86.5958,
                rating: 4.8,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on leashes at this popular beach. The park features towering sand dunes and beautiful Lake Michigan shoreline.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 0,
                source: "internet_search",
                reviews: [
                    Review(
                        user: "Michelle S.",
                        rating: 5,
                        comment: "Amazing sand dunes! My dog had so much fun climbing them. Great for exercise.",
                        date: Date().addingTimeInterval(-86400 * 6),
                        userPhotos: [],
                        isHelpful: 15,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_silver_lake",
                name: "Silver Lake State Park",
                type: .beach,
                address: "9679 W State Park Rd, Mears, MI 49436",
                latitude: 43.6689,
                longitude: -86.5389,
                rating: 4.7,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are allowed on leashes at this beautiful beach. The area offers stunning views of Lake Michigan and the Silver Lake Sand Dunes.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 0,
                source: "internet_search",
                reviews: [
                    Review(
                        user: "David M.",
                        rating: 4,
                        comment: "Beautiful beach with great sand dunes. My dog loved playing in the sand.",
                        date: Date().addingTimeInterval(-86400 * 4),
                        userPhotos: [],
                        isHelpful: 7,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            Place(
                id: "beach_muskegon",
                name: "Muskegon State Park",
                type: .beach,
                address: "3560 Memorial Dr, North Muskegon, MI 49445",
                latitude: 43.2747,
                longitude: -86.3489,
                rating: 4.8,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Dogs are welcome on leashes at this Lake Michigan beach. The park features beautiful shoreline and excellent facilities.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 0,
                source: "internet_search",
                reviews: [
                    Review(
                        user: "Lisa T.",
                        rating: 5,
                        comment: "Perfect beach for dogs! Great facilities and beautiful views. My dog had a blast.",
                        date: Date().addingTimeInterval(-86400 * 3),
                        userPhotos: [],
                        isHelpful: 11,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            
            // Additional Michigan Dog-Friendly Places
            Place(
                id: "coffee_4",
                name: "Madcap Coffee Company",
                type: .coffee,
                address: "98 Monroe Center St NW, Grand Rapids, MI 49503",
                latitude: 42.9634,
                longitude: -85.6681,
                rating: 4.7,
                tags: ["dogMenu", "indoorAllowed", "waterBowl"],
                notes: "Artisan coffee roaster with dog-friendly outdoor seating. Known for their single-origin beans and welcoming atmosphere for dog owners.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 15,
                source: "local_business_directory",
                reviews: [
                    Review(
                        user: "Coffee Lover",
                        rating: 5,
                        comment: "Amazing coffee and they love dogs! My pup gets treats and water.",
                        date: Date().addingTimeInterval(-86400 * 7),
                        userPhotos: [],
                        isHelpful: 5,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: true,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            
            Place(
                id: "trail_2",
                name: "Nordhouse Dunes Wilderness",
                type: .trail,
                address: "Nordhouse Dunes, Ludington, MI 49431",
                latitude: 44.0375,
                longitude: -86.4668,
                rating: 4.9,
                tags: ["offLeash", "outdoorOnly", "waterBowl"],
                notes: "Stunning wilderness area with pristine Lake Michigan beaches and hiking trails. Dogs can be off-leash in designated areas. Perfect for adventurous dogs and their owners.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 20,
                source: "national_forest_service",
                reviews: [
                    Review(
                        user: "Nature Explorer",
                        rating: 5,
                        comment: "Incredible dunes and beach access. My dog had the time of his life running free!",
                        date: Date().addingTimeInterval(-86400 * 14),
                        userPhotos: [],
                        isHelpful: 8,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: true,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            
            Place(
                id: "park_2",
                name: "Huron-Clinton Metroparks - Kensington",
                type: .park,
                address: "4570 Huron River Pkwy, Milford, MI 48380",
                latitude: 42.5833,
                longitude: -83.6167,
                rating: 4.6,
                tags: ["waterBowl", "onLeashOnly", "outdoorOnly"],
                notes: "Beautiful metro park with lakes, trails, and picnic areas. Dogs must be on-leash but there's plenty of space to explore and water stations throughout the park.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 18,
                source: "metro_parks_system",
                reviews: [
                    Review(
                        user: "Park Regular",
                        rating: 4,
                        comment: "Great trails and lake views. Always clean and well-maintained. Perfect for a long walk with the dog.",
                        date: Date().addingTimeInterval(-86400 * 10),
                        userPhotos: [],
                        isHelpful: 6,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: false,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            ),
            
            Place(
                id: "coffee_5",
                name: "Rowster Coffee",
                type: .coffee,
                address: "563 Wealthy St SE, Grand Rapids, MI 49503",
                latitude: 42.9569,
                longitude: -85.6581,
                rating: 4.5,
                tags: ["dogMenu", "indoorAllowed", "waterBowl"],
                notes: "Local coffee shop with dog-friendly patio seating. Known for their excellent espresso and welcoming attitude toward four-legged customers.",
                userName: "PawMap System",
                isAutoLoaded: true,
                verificationCount: 12,
                source: "local_business_directory",
                reviews: [
                    Review(
                        user: "Espresso Fan",
                        rating: 4,
                        comment: "Great coffee and the staff always remembers my dog's name!",
                        date: Date().addingTimeInterval(-86400 * 5),
                        userPhotos: [],
                        isHelpful: 4,
                        helpfulVoters: []
                    )
                ],
                dogAmenities: DogAmenities(
                    hasDogBowl: true,
                    hasIndoorAccess: false,
                    isOutdoorOnly: true,
                    hasDogTreats: true,
                    hasWaterStation: true,
                    hasShade: true,
                    hasFencedArea: false,
                    allowsOffLeash: false,
                    hasWasteBags: true,
                    hasDogWash: false
                ),
                images: [],
                createdAt: Date(),
                updatedAt: Date(),
                reports: [],
                isVerified: true
            )
        ]
        
        places = samplePlaces
        filteredPlaces = samplePlaces
        savePlaces()
    }
    
    func addPlace(_ place: Place) {
        places.append(place)
        filteredPlaces = places
        savePlaces()
    }
    
    func deletePlace(_ place: Place) {
        places.removeAll { $0.id == place.id }
        filteredPlaces = places
        savePlaces()
    }
    
    func updatePlace(_ place: Place) {
        if let index = places.firstIndex(where: { $0.id == place.id }) {
            places[index] = place
            filteredPlaces = places
            savePlaces()
        }
    }
    
    func filterPlaces(by type: Place.PlaceType?) {
        if let type = type {
            filteredPlaces = places.filter { $0.type == type }
        } else {
            filteredPlaces = places
        }
    }
    
    func searchPlaces(query: String) {
        if query.isEmpty {
            filteredPlaces = places
        } else {
            filteredPlaces = places.filter { place in
                place.name.localizedCaseInsensitiveContains(query) ||
                place.address.localizedCaseInsensitiveContains(query) ||
                place.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
    }
    
    func addReview(to placeId: String, review: Review) {
        if let index = places.firstIndex(where: { $0.id == placeId }) {
            var updatedPlace = places[index]
            var updatedReviews = updatedPlace.reviews
            updatedReviews.append(review)
            
            // 重新计算评分
            let totalRating = updatedReviews.reduce(0) { $0 + $1.rating }
            let newRating = Double(totalRating) / Double(updatedReviews.count)
            
            let newPlace = Place(
                id: updatedPlace.id,
                name: updatedPlace.name,
                type: updatedPlace.type,
                address: updatedPlace.address,
                latitude: updatedPlace.latitude,
                longitude: updatedPlace.longitude,
                rating: newRating,
                tags: updatedPlace.tags,
                notes: updatedPlace.notes,
                userName: updatedPlace.userName,
                isAutoLoaded: updatedPlace.isAutoLoaded,
                verificationCount: updatedPlace.verificationCount,
                source: updatedPlace.source,
                reviews: updatedReviews,
                dogAmenities: updatedPlace.dogAmenities,
                images: updatedPlace.images,
                createdAt: updatedPlace.createdAt,
                updatedAt: Date(),
                reports: updatedPlace.reports,
                isVerified: updatedPlace.isVerified
            )
            
            places[index] = newPlace
            filteredPlaces = places
            savePlaces()
        }
    }
    
    func addReview(to place: Place, review: Review) {
        if let index = places.firstIndex(where: { $0.id == place.id }) {
            var updatedPlace = places[index]
            var updatedReviews = updatedPlace.reviews
            updatedReviews.append(review)
            
            // 重新计算评分
            let totalRating = updatedReviews.reduce(0) { $0 + $1.rating }
            let newRating = Double(totalRating) / Double(updatedReviews.count)
            
            let newPlace = Place(
                id: updatedPlace.id,
                name: updatedPlace.name,
                type: updatedPlace.type,
                address: updatedPlace.address,
                latitude: updatedPlace.latitude,
                longitude: updatedPlace.longitude,
                rating: newRating,
                tags: updatedPlace.tags,
                notes: updatedPlace.notes,
                userName: updatedPlace.userName,
                isAutoLoaded: updatedPlace.isAutoLoaded,
                verificationCount: updatedPlace.verificationCount,
                source: updatedPlace.source,
                reviews: updatedReviews,
                dogAmenities: updatedPlace.dogAmenities,
                images: updatedPlace.images,
                createdAt: updatedPlace.createdAt,
                updatedAt: Date(),
                reports: updatedPlace.reports,
                isVerified: updatedPlace.isVerified
            )
            
            places[index] = newPlace
            filteredPlaces = places
            savePlaces()
        }
    }
    
    private func savePlaces() {
        if let data = try? JSONEncoder().encode(places) {
            userDefaults.set(data, forKey: placesKey)
        }
    }
    
    private func loadPlaces() {
        if let data = userDefaults.data(forKey: placesKey),
           let loadedPlaces = try? JSONDecoder().decode([Place].self, from: data) {
            places = loadedPlaces
            filteredPlaces = loadedPlaces
        }
    }
    
    // MARK: - User-Generated Content Management
    
    func addUserPlace(_ place: Place) {
        places.append(place)
        filteredPlaces = places
        savePlaces()
    }
    
    func reportPlace(placeId: String, reporterId: String, reporterName: String, reason: PlaceReport.ReportReason, description: String) {
        guard let index = places.firstIndex(where: { $0.id == placeId }) else { return }
        
        let report = PlaceReport(
            placeId: placeId,
            reporterId: reporterId,
            reporterName: reporterName,
            reason: reason,
            description: description,
            date: Date(),
            isResolved: false
        )
        
        var updatedPlace = places[index]
        var updatedReports = updatedPlace.reports
        updatedReports.append(report)
        
        // Create updated place with new report
        let newPlace = Place(
            id: updatedPlace.id,
            name: updatedPlace.name,
            type: updatedPlace.type,
            address: updatedPlace.address,
            latitude: updatedPlace.latitude,
            longitude: updatedPlace.longitude,
            rating: updatedPlace.rating,
            tags: updatedPlace.tags,
            notes: updatedPlace.notes,
            userName: updatedPlace.userName,
            isAutoLoaded: updatedPlace.isAutoLoaded,
            verificationCount: updatedPlace.verificationCount,
            source: updatedPlace.source,
            reviews: updatedPlace.reviews,
            dogAmenities: updatedPlace.dogAmenities,
            images: updatedPlace.images,
            createdAt: updatedPlace.createdAt,
            updatedAt: Date(),
            reports: updatedReports,
            isVerified: updatedPlace.isVerified
        )
        
        places[index] = newPlace
        filteredPlaces = places
        savePlaces()
    }
    
    func deletePlace(placeId: String) {
        places.removeAll { $0.id == placeId }
        filteredPlaces = places
        savePlaces()
    }
    
    func getPlacesWithReports() -> [Place] {
        return places.filter { !$0.reports.isEmpty }
    }
    
    func getUnresolvedReports() -> [PlaceReport] {
        return places.flatMap { $0.reports }.filter { !$0.isResolved }
    }
}
