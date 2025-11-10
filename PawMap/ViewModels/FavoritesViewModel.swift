import Foundation
import Combine

/// ViewModel for managing user favorites with Firebase integration
class FavoritesViewModel: ObservableObject {
    @Published var favoritePlaces: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadFavorites()
                } else {
                    self?.favoritePlaces = []
                }
            }
            .store(in: &cancellables)
    }
    
    func loadFavorites() {
        guard let userId = authService.currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        firebaseService.readDocument(UserFavorites.self, from: "favorites", withId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] userFavorites in
                    if let userFavorites = userFavorites {
                        self?.loadFavoritePlaces(placeIds: userFavorites.placeIds)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadFavoritePlaces(placeIds: [String]) {
        guard !placeIds.isEmpty else {
            favoritePlaces = []
            return
        }
        
        firebaseService.queryDocuments(
            Place.self,
            from: "places",
            where: [("id", .in, placeIds)]
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] places in
                self?.favoritePlaces = places
            }
        )
        .store(in: &cancellables)
    }
    
    func addToFavorites(_ place: Place) {
        guard let userId = authService.currentUser?.uid else { return }
        
        firebaseService.readDocument(UserFavorites.self, from: "favorites", withId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] userFavorites in
                    let updatedFavorites = (userFavorites ?? UserFavorites(userId: userId))
                        .addingPlace(place.id)
                    
                    self?.firebaseService.updateDocument(updatedFavorites, in: "favorites", withId: userId)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in
                                self?.loadFavorites()
                            }
                        )
                        // .store(in: &self.cancellables) // Commented out due to capture semantics issue
                }
            )
            .store(in: &cancellables)
    }
    
    func removeFromFavorites(_ place: Place) {
        guard let userId = authService.currentUser?.uid else { return }
        
        firebaseService.readDocument(UserFavorites.self, from: "favorites", withId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] userFavorites in
                    guard let userFavorites = userFavorites else { return }
                    
                    let updatedFavorites = userFavorites.removingPlace(place.id)
                    
                    self?.firebaseService.updateDocument(updatedFavorites, in: "favorites", withId: userId)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in
                                self?.loadFavorites()
                            }
                        )
                        // .store(in: &self.cancellables) // Commented out due to capture semantics issue
                }
            )
            .store(in: &cancellables)
    }
    
    func isFavorite(_ place: Place) -> Bool {
        return favoritePlaces.contains { $0.id == place.id }
    }
    
    func toggleFavorite(_ place: Place) {
        if isFavorite(place) {
            removeFromFavorites(place)
        } else {
            addToFavorites(place)
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
