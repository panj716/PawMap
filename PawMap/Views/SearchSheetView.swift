import SwiftUI
import CoreLocation

struct SearchSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @Binding var searchText: String
    
    @State private var searchResults: [Place] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Place, address, tag, or US ZIP (e.g. 48104)", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                if isSearching {
                    VStack {
                        Spacer()
                        ProgressView("Searching…")
                        Spacer()
                    }
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No results")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else if searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Search dog-friendly places")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter a name, address, or tag")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Popular searches")
                                .font(.headline)
                                .padding(.top, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(["Coffee", "Dog park", "Beach", "Trail"], id: \.self) { tag in
                                    Button(action: {
                                        searchText = tag
                                        performSearch(query: tag)
                                    }) {
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                } else {
                    List(searchResults) { place in
                        SearchResultRow(place: place)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let digitsOnly = trimmed.filter(\.isNumber)
        // US ZIP: 5 digits, or ZIP+4 (9 digits, often typed with a hyphen)
        let looksLikeUSZip = digitsOnly.count == 5 || (digitsOnly.count == 9 && trimmed.contains("-"))
        
        if looksLikeUSZip {
            let zip = String(digitsOnly.prefix(5))
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(zip) { placemarks, error in
                DispatchQueue.main.async {
                    defer { self.isSearching = false }
                    guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
                        // Fallback: substring match on address (zip appears in many addresses)
                        self.searchResults = self.placeViewModel.places.filter { $0.address.contains(zip) }
                        return
                    }
                    let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let radiusMeters = 10.0 * 1609.344
                    self.searchResults = self.placeViewModel.places.filter { place in
                        let loc = CLLocation(latitude: place.latitude, longitude: place.longitude)
                        return center.distance(from: loc) <= radiusMeters
                    }
                    .sorted { $0.name < $1.name }
                }
            }
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let q = trimmed
            searchResults = placeViewModel.places.filter { place in
                place.name.localizedCaseInsensitiveContains(q) ||
                place.address.localizedCaseInsensitiveContains(q) ||
                place.notes.localizedCaseInsensitiveContains(q) ||
                place.tags.contains { $0.localizedCaseInsensitiveContains(q) } ||
                place.type.displayName.localizedCaseInsensitiveContains(q)
            }
            .sorted { $0.name < $1.name }
            isSearching = false
        }
    }
}

struct SearchResultRow: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(placeColor(for: place.type))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: place.type.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                }
                
                // Place info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(place.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if userManager.isFavorite(placeId: place.id) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text(place.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                        }
                        
                        Text(String(format: "%.1f", place.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(place.type.displayName)
                            .font(.caption)
                            .foregroundColor(placeColor(for: place.type))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(placeColor(for: place.type).opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            PlaceDetailView(place: place)
        }
    }
}

private func placeColor(for type: Place.PlaceType) -> Color {
    switch type {
    case .coffee: return .orange
    case .trail: return .green
    case .park: return .blue
    case .beach: return .cyan
    case .shop: return .purple
    case .camp: return .brown
    case .restaurant: return .red
    case .other: return .gray
    }
}

#Preview {
    SearchSheetView(searchText: .constant(""))
        .environmentObject(PlacesManager())
        .environmentObject(PlaceViewModel())
        .environmentObject(UserManager())
}
