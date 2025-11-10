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
    
    // Filtering
    @Published var selectedFilter: Place.PlaceType?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .rating
    
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
        setupSubscriptions()
        loadPlaces()
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
        
        firebaseService.listenToCollection(Place.self, from: "places")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] places in
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
