import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

/// ViewModel for managing places data with Firebase integration
class PlaceViewModel: ObservableObject {
    @Published var places: [Place] = []
    @Published var filteredPlaces: [Place] = []
    @Published var selectedPlace: Place?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var pendingSeedWrites = 0
    
    // Filtering
    @Published var selectedFilter: Place.PlaceType?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .rating
    @Published private(set) var zipcodeCenter: CLLocationCoordinate2D?
    @Published private(set) var zipcodeRadiusMiles: Double = 10.0
    
    enum SortOption: String, CaseIterable {
        case rating = "rating"
        case distance = "distance"
        case newest = "newest"
        case name = "name"
        
        var displayName: String {
            switch self {
            case .rating: return "Rating"
            case .distance: return "Distance"
            case .newest: return "Newest"
            case .name: return "Name"
            }
        }
    }
    
    init() {
        print("🚀 [Places] PlaceViewModel init")
        setupSubscriptions()
        loadPlaces()
        // Keep migration logic, but also force a seed upsert each app launch.
        // IDs are stable, so this updates existing docs instead of duplicating.
        migrateSampleDataIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            print("🧪 [Places] Force seed upsert on launch")
            self?.uploadSampleData()
        }
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Listen to filter changes
        Publishers.CombineLatest3($selectedFilter, $searchText, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] filter, search, sort in
                self?.applyFilters(filter: filter, search: search, sort: sort)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadPlaces() {
        isLoading = true
        errorMessage = nil
        print("🛰️ [Places] Starting Firestore listener for places collection")
        
        firebaseService.listenToCollection(Place.self, from: "places")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ [Places] Firestore listener failed: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] places in
                    let sampleNames = places.prefix(8).map(\.name).joined(separator: ", ")
                    print("✅ [Places] Loaded \(places.count) place(s) from Firestore")
                    print("📍 [Places] Sample names: \(sampleNames)")
                    self?.places = places
                    self?.applyFilters(filter: self?.selectedFilter, search: self?.searchText ?? "", sort: self?.sortOption ?? .rating)
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshPlaces() {
        loadPlaces()
    }
    
    // MARK: - Place Management
    
    func addPlace(_ place: Place) -> AnyPublisher<Void, Error> {
        guard let userId = authService.currentUser?.uid else {
            return Fail(error: FirebaseError.authenticationRequired)
                .eraseToAnyPublisher()
        }
        
        let placeWithUser = Place(
            id: place.id,
            name: place.name,
            type: place.type,
            address: place.address,
            latitude: place.latitude,
            longitude: place.longitude,
            rating: place.rating,
            tags: place.tags,
            notes: place.notes,
            createdBy: userId,
            createdAt: place.createdAt,
            updatedAt: place.updatedAt,
            isVerified: place.isVerified,
            reportCount: place.reportCount,
            images: place.images,
            dogAmenities: place.dogAmenities
        )
        
        return firebaseService.createDocument(placeWithUser, in: "places", withId: place.id)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func updatePlace(_ place: Place) -> AnyPublisher<Void, Error> {
        return firebaseService.updateDocument(place, in: "places", withId: place.id)
    }
    
    func deletePlace(_ place: Place) -> AnyPublisher<Void, Error> {
        return firebaseService.deleteDocument(from: "places", withId: place.id)
    }
    
    // MARK: - Place Selection
    
    func selectPlace(_ place: Place) {
        selectedPlace = place
    }
    
    func clearSelection() {
        selectedPlace = nil
    }
    
    // MARK: - Filtering and Search
    
    private func applyFilters(filter: Place.PlaceType?, search: String, sort: SortOption) {
        var filtered = places
        let beforeCount = filtered.count

        // Apply zipcode radius filter first (distance-based)
        if let center = zipcodeCenter {
            let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let maxDistanceMeters = zipcodeRadiusMiles * 1609.344
            filtered = filtered.filter { place in
                let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                return centerLocation.distance(from: placeLocation) <= maxDistanceMeters
            }
        }
        
        // Apply type filter
        if let filter = filter {
            filtered = filtered.filter { $0.type == filter }
        }
        
        // Apply search filter
        if !search.isEmpty {
            filtered = filtered.filter { place in
                place.name.localizedCaseInsensitiveContains(search) ||
                place.address.localizedCaseInsensitiveContains(search) ||
                place.notes.localizedCaseInsensitiveContains(search) ||
                place.tags.contains { $0.localizedCaseInsensitiveContains(search) }
            }
        }
        
        // Apply sorting
        filtered = sortPlaces(filtered, by: sort)
        
        DispatchQueue.main.async {
            self.filteredPlaces = filtered
            let afterCount = filtered.count
            let names = filtered.prefix(8).map(\.name).joined(separator: ", ")
            if self.zipcodeCenter != nil {
                print("🔎 [Places] Zipcode filter applied: \(beforeCount) -> \(afterCount) within \(self.zipcodeRadiusMiles) mile(s)")
                print("🗺️ [Places] Filtered sample: \(names)")
            } else {
                print("🔎 [Places] General filter applied: \(beforeCount) -> \(afterCount)")
            }
        }
    }
    
    private func sortPlaces(_ places: [Place], by option: SortOption) -> [Place] {
        switch option {
        case .rating:
            return places.sorted { $0.rating > $1.rating }
        case .newest:
            return places.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return places.sorted { $0.name < $1.name }
        case .distance:
            // This would require user location - for now, sort by rating
            return places.sorted { $0.rating > $1.rating }
        }
    }
    
    func setFilter(_ filter: Place.PlaceType?) {
        selectedFilter = filter
    }
    
    func setSearchText(_ text: String) {
        searchText = text
    }
    
    func setSortOption(_ option: SortOption) {
        sortOption = option
    }

    // MARK: - Zipcode Search

    func setZipcodeSearch(center: CLLocationCoordinate2D, radiusMiles: Double = 10.0) {
        zipcodeCenter = center
        zipcodeRadiusMiles = radiusMiles
        print("📮 [Places] Set zipcode center to (\(center.latitude), \(center.longitude)), radius: \(radiusMiles) miles")
        applyFilters(filter: selectedFilter, search: searchText, sort: sortOption)
    }

    func clearZipcodeSearch() {
        zipcodeCenter = nil
        zipcodeRadiusMiles = 10.0
        applyFilters(filter: selectedFilter, search: searchText, sort: sortOption)
    }
    
    // MARK: - Place Statistics
    
    func getPlaceStats(for place: Place) -> AnyPublisher<PlaceStats, Error> {
        return Publishers.CombineLatest3(
            firebaseService.listenToCollection(Review.self, from: "reviews", where: "placeId", isEqualTo: place.id),
            firebaseService.listenToCollection(PlaceReport.self, from: "reports", where: "placeId", isEqualTo: place.id),
            getFavoriteCount(for: place.id)
        )
        .map { reviews, reports, favoriteCount in
            PlaceStats(
                placeId: place.id,
                reviewCount: reviews.count,
                averageRating: reviews.isEmpty ? 0.0 : Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count),
                reportCount: reports.count,
                favoriteCount: favoriteCount,
                lastUpdated: Date()
            )
        }
        .eraseToAnyPublisher()
    }
    
    private func getFavoriteCount(for placeId: String) -> AnyPublisher<Int, Error> {
        return firebaseService.queryDocuments(
            UserFavorites.self,
            from: "favorites",
            where: [("placeIds", .arrayContains, placeId)]
        )
        .map { $0.count }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Nearby Places
    
    func getNearbyPlaces(center: CLLocationCoordinate2D, radius: Double = 10.0) -> [Place] {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        return places.filter { place in
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = centerLocation.distance(from: placeLocation) / 1000 // Convert to kilometers
            return distance <= radius
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Data Migration
    
    /// Migrate data from UserDefaults to Firebase (only runs once)
    private func migrateSampleDataIfNeeded() {
        let migrationKey = "hasMigratedPlacesToFirebase_v4_system_upsert_no_auth"
        print("🧭 [Places] Checking migration key: \(migrationKey)")
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("✅ Migration already completed, skipping")
            return // Already migrated
        }
        
        // Wait a bit for Firebase to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // First, try to migrate places from UserDefaults
            self.migrateUserDefaultsPlaces()
            
            // Always upsert this seed batch once for this migration version.
            // Sample place IDs are stable, so repeated writes update instead of duplicating.
            print("📦 Running v2 metro Detroit sample data upsert...")
            self.uploadSampleData()
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
    
    /// Migrate all places from UserDefaults to Firebase
    private func migrateUserDefaultsPlaces() {
        // Load places from UserDefaults (same key used by PlacesManager)
        guard let data = UserDefaults.standard.data(forKey: "places"),
              let localPlaces = try? JSONDecoder().decode([Place].self, from: data),
              !localPlaces.isEmpty else {
            print("📭 No places found in UserDefaults to migrate")
            return
        }
        
        print("📦 Found \(localPlaces.count) places in UserDefaults, migrating to Firebase...")
        
        // Upload each place to Firebase
        for place in localPlaces {
            // Skip if place ID already exists (to avoid duplicates)
            addPlace(place)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Failed to migrate place '\(place.name)': \(error.localizedDescription)")
                        } else {
                            print("✅ Successfully migrated place: \(place.name) (\(place.type.rawValue))")
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        print("✅ Finished migrating \(localPlaces.count) places from UserDefaults to Firebase")
    }
    
    /// Upload sample places to Firebase
    private func uploadSampleData() {
        func makeAmenities(outdoorOnly: Bool = false, hasWater: Bool = false, fenced: Bool = false, offLeash: Bool = false) -> DogAmenities {
            DogAmenities(
                hasDogBowl: false,
                hasIndoorAccess: !outdoorOnly,
                isOutdoorOnly: outdoorOnly,
                hasDogTreats: false,
                hasWaterStation: hasWater,
                hasShade: true,
                hasFencedArea: fenced,
                allowsOffLeash: offLeash,
                hasWasteBags: true,
                hasDogWash: false
            )
        }

        let samplePlaces = [
            // Troy
            Place(
                id: "troy_beach_woods_1",
                name: "Beach Woods Park",
                type: .park,
                address: "Beach Rd, Troy, MI 48083",
                latitude: 42.5655,
                longitude: -83.1333,
                rating: 4.4,
                tags: ["metroDetroit", "troy", "park", "dogFriendly"],
                notes: "Large city park with walking paths and open green space for on-leash dogs.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true, hasWater: true)
            ),
            Place(
                id: "troy_boulan_park_1",
                name: "Boulan Park",
                type: .park,
                address: "4115 Crooks Rd, Troy, MI 48098",
                latitude: 42.5907,
                longitude: -83.1729,
                rating: 4.3,
                tags: ["metroDetroit", "troy", "park"],
                notes: "Neighborhood park with trails and open lawn for dog walks.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),
            Place(
                id: "troy_biggby_1",
                name: "BIGGBY Coffee - Troy",
                type: .coffee,
                address: "4885 Rochester Rd, Troy, MI 48085",
                latitude: 42.5850,
                longitude: -83.1339,
                rating: 4.2,
                tags: ["metroDetroit", "troy", "coffee", "outdoorSeating"],
                notes: "Dog-friendly patio seating and quick service coffee stop.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),

            // Birmingham
            Place(
                id: "birmingham_shain_park_1",
                name: "Shain Park",
                type: .park,
                address: "270 W Merrill St, Birmingham, MI 48009",
                latitude: 42.5458,
                longitude: -83.2144,
                rating: 4.4,
                tags: ["metroDetroit", "birmingham", "park"],
                notes: "Downtown green space with walkable streets nearby for short dog walks.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),
            Place(
                id: "birmingham_booth_park_1",
                name: "Booth Park",
                type: .park,
                address: "435 North St, Birmingham, MI 48009",
                latitude: 42.5538,
                longitude: -83.2088,
                rating: 4.5,
                tags: ["metroDetroit", "birmingham", "park"],
                notes: "Tree-lined park with paths and shaded spots.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true, hasWater: true)
            ),
            Place(
                id: "birmingham_commonwealth_1",
                name: "Commonwealth Cafe",
                type: .restaurant,
                address: "300 Hamilton Row, Birmingham, MI 48009",
                latitude: 42.5462,
                longitude: -83.2141,
                rating: 4.3,
                tags: ["metroDetroit", "birmingham", "restaurant", "patio"],
                notes: "Popular patio dining option where dogs are often welcome outdoors.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true),
                restaurantSeatingType: .outdoor
            ),

            // Ann Arbor
            Place(
                id: "annarbor_swift_run_1",
                name: "Swift Run Dog Park",
                type: .park,
                address: "3000 Oakbrook Dr, Ann Arbor, MI 48104",
                latitude: 42.2464,
                longitude: -83.7417,
                rating: 4.6,
                tags: ["metroDetroit", "annArbor", "park", "offLeash", "fenced"],
                notes: "Dedicated dog park with separate areas and reliable dog-owner traffic.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true, hasWater: true, fenced: true, offLeash: true)
            ),
            Place(
                id: "annarbor_arb_1",
                name: "Nichols Arboretum",
                type: .trail,
                address: "1610 Washington Heights, Ann Arbor, MI 48104",
                latitude: 42.2808,
                longitude: -83.7251,
                rating: 4.7,
                tags: ["metroDetroit", "annArbor", "trail"],
                notes: "Scenic trail network with many on-leash walking routes.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),
            Place(
                id: "annarbor_roosroast_1",
                name: "RoosRoast Coffee",
                type: .coffee,
                address: "117 E Liberty St, Ann Arbor, MI 48104",
                latitude: 42.2796,
                longitude: -83.7462,
                rating: 4.3,
                tags: ["metroDetroit", "annArbor", "coffee", "outdoorSeating"],
                notes: "Local coffee shop with dog-friendly outdoor seating.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),

            // Royal Oak
            Place(
                id: "royaloak_starr_jaycee_1",
                name: "Starr Jaycee Park",
                type: .park,
                address: "13 Mile Rd & Crooks Rd, Royal Oak, MI 48073",
                latitude: 42.5193,
                longitude: -83.1681,
                rating: 4.5,
                tags: ["metroDetroit", "royalOak", "park", "dogPark"],
                notes: "Includes a popular dog-friendly section and open trails.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true, hasWater: true, fenced: true)
            ),
            Place(
                id: "royaloak_catalpa_1",
                name: "Catalpa Oaks County Park",
                type: .park,
                address: "27725 Greenfield Rd, Southfield, MI 48076",
                latitude: 42.5058,
                longitude: -83.2057,
                rating: 4.4,
                tags: ["metroDetroit", "royalOak", "park"],
                notes: "Short-drive option from Royal Oak with walking paths.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),
            Place(
                id: "royaloak_atomic_1",
                name: "Atomic Coffee",
                type: .coffee,
                address: "401 S Main St, Royal Oak, MI 48067",
                latitude: 42.4862,
                longitude: -83.1446,
                rating: 4.2,
                tags: ["metroDetroit", "royalOak", "coffee", "patio"],
                notes: "Great stop during downtown Royal Oak dog walks.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),

            // Sterling Heights
            Place(
                id: "sterling_dodge_park_1",
                name: "Dodge Park",
                type: .park,
                address: "40620 Utica Rd, Sterling Heights, MI 48313",
                latitude: 42.5938,
                longitude: -83.0302,
                rating: 4.5,
                tags: ["metroDetroit", "sterlingHeights", "park"],
                notes: "Large community park with broad walking paths.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true, hasWater: true)
            ),
            Place(
                id: "sterling_freedom_hill_1",
                name: "Freedom Hill Trail Area",
                type: .trail,
                address: "14900 Metropolitan Pkwy, Sterling Heights, MI 48312",
                latitude: 42.5578,
                longitude: -82.9748,
                rating: 4.3,
                tags: ["metroDetroit", "sterlingHeights", "trail"],
                notes: "Easy trail routes and open areas suitable for on-leash dogs.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            ),
            Place(
                id: "sterling_golden_1",
                name: "Golden Coffee Box",
                type: .coffee,
                address: "37882 Van Dyke Ave, Sterling Heights, MI 48312",
                latitude: 42.5694,
                longitude: -83.0284,
                rating: 4.1,
                tags: ["metroDetroit", "sterlingHeights", "coffee"],
                notes: "Casual coffee spot with nearby sidewalks for quick dog breaks.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: [],
                dogAmenities: makeAmenities(outdoorOnly: true)
            )
        ]
        
        let reviewTaggedSamplePlaces = samplePlaces.map { place in
            Place(
                id: place.id,
                name: place.name,
                type: place.type,
                address: place.address,
                latitude: place.latitude,
                longitude: place.longitude,
                rating: place.rating,
                tags: Array(Set(place.tags + ["needsReview"])).sorted(),
                notes: place.notes,
                createdBy: place.createdBy,
                createdAt: place.createdAt,
                updatedAt: place.updatedAt,
                isVerified: false,
                reportCount: place.reportCount,
                images: place.images,
                dogAmenities: place.dogAmenities,
                restaurantSeatingType: place.restaurantSeatingType
            )
        }
        
        pendingSeedWrites = reviewTaggedSamplePlaces.count
        print("📦 [Places] Starting seed upsert for \(pendingSeedWrites) places")

        // Upload each sample place to Firebase as a system upsert (no auth requirement).
        for place in reviewTaggedSamplePlaces {
            firebaseService.createDocument(place, in: "places", withId: place.id)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Failed to migrate sample place \(place.name): \(error.localizedDescription)")
                        } else {
                            print("✅ Successfully migrated sample place: \(place.name)")
                        }
                        self.pendingSeedWrites -= 1
                        if self.pendingSeedWrites == 0 {
                            print("🔄 [Places] Seed upsert finished, forcing refreshPlaces()")
                            self.refreshPlaces()
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }
}

// MARK: - Supporting Types

struct PlaceStats: Codable {
    let placeId: String
    let reviewCount: Int
    let averageRating: Double
    let reportCount: Int
    let favoriteCount: Int
    let lastUpdated: Date
}
