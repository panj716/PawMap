import Foundation
import Combine
import CoreLocation

/// ViewModel for managing Top Picks with Firebase integration
class TopPicksViewModel: ObservableObject {
    @Published var nationalFavorites: [CuratedPlace] = []
    @Published var nearbyFavorites: [CuratedPlace] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let locationService = LocationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTopPicks()
        setupLocationListener()
    }
    
    private func setupLocationListener() {
        locationService.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                if let location = location {
                    self?.updateNearbyFavorites(userLocation: location)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadTopPicks() {
        isLoading = true
        errorMessage = nil
        
        // Load national favorites
        firebaseService.readDocument(TopPicksDocument.self, from: "topPicks", withId: "national")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] topPicksDocument in
                    self?.nationalFavorites = topPicksDocument?.places ?? []
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateNearbyFavorites(userLocation: CLLocation) {
        // Filter national favorites by distance
        let nearbyRadius: Double = 30.0 // 30 miles
        
        nearbyFavorites = nationalFavorites.filter { curatedPlace in
            let placeLocation = CLLocation(
                latitude: curatedPlace.latitude,
                longitude: curatedPlace.longitude
            )
            let distance = userLocation.distance(from: placeLocation) / 1000 // Convert to kilometers
            return distance <= nearbyRadius
        }
    }
    
    func refreshTopPicks() {
        loadTopPicks()
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Supporting Types

struct TopPicksDocument: Codable {
    let places: [CuratedPlace]
    let lastUpdated: Date
    let algorithm: String
    
    init(places: [CuratedPlace], lastUpdated: Date = Date(), algorithm: String = "rating_review_volume") {
        self.places = places
        self.lastUpdated = lastUpdated
        self.algorithm = algorithm
    }
}

