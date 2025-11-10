import Foundation
import CoreLocation

class PlacesManager: ObservableObject {
    @Published var places: [Place] = []
    @Published var filteredPlaces: [Place] = []
    @Published var searchText = ""
    @Published var selectedFilters: Set<Place.PlaceType> = []
    @Published var selectedPlace: Place?
    
    init() {
        loadPlaces()
        // Always load sample data to ensure we have the latest places
        loadSampleData()
    }
    
    func loadSampleData() {
        let samplePlaces = [
            // Sample places with simplified structure
            Place(
                id: "park_1",
                name: "Swift Run Dog Park",
                type: .park,
                address: "Swift Run Dog Park, Ann Arbor, MI",
                latitude: 42.2464,
                longitude: -83.7417,
                rating: 4.5,
                tags: ["offLeash", "fenced"],
                notes: "A great dog park with separate areas for large and small dogs.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: []
            ),
            Place(
                id: "coffee_1",
                name: "RoosRoast Coffee",
                type: .coffee,
                address: "117 E Liberty St, Ann Arbor, MI 48104",
                latitude: 42.2796,
                longitude: -83.7462,
                rating: 4.3,
                tags: ["dogFriendly", "outdoorSeating"],
                notes: "Local coffee shop that welcomes dogs on their outdoor patio.",
                createdBy: "system",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: []
            )
        ]
        
        places = samplePlaces
        filteredPlaces = places
        savePlaces()
    }
    
    func loadPlaces() {
        // Load from UserDefaults for now (will be replaced with Firebase)
        if let data = UserDefaults.standard.data(forKey: "places"),
           let decodedPlaces = try? JSONDecoder().decode([Place].self, from: data) {
            places = decodedPlaces
            filteredPlaces = places
        }
    }
    
    func savePlaces() {
        // Save to UserDefaults for now (will be replaced with Firebase)
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: "places")
        }
    }
    
    func addPlace(_ place: Place) {
        places.append(place)
        filteredPlaces = places
        savePlaces()
    }
    
    func filterPlaces() {
        var filtered = places
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText) ||
                place.address.localizedCaseInsensitiveContains(searchText) ||
                place.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filters
        if !selectedFilters.isEmpty {
            filtered = filtered.filter { place in
                selectedFilters.contains(place.type)
            }
        }
        
        filteredPlaces = filtered
    }
    
    func toggleFilter(_ type: Place.PlaceType) {
        if selectedFilters.contains(type) {
            selectedFilters.remove(type)
        } else {
            selectedFilters.insert(type)
        }
        filterPlaces()
    }
    
    func clearFilters() {
        selectedFilters.removeAll()
        filterPlaces()
    }
    
    func searchPlaces(_ query: String) {
        searchText = query
        filterPlaces()
    }
}