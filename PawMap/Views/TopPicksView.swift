import SwiftUI
import CoreLocation

struct TopPicksView: View {
    @StateObject private var curatedPlacesManager = CuratedPlacesManager.shared
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedPlace: CuratedPlace?
    @State private var showingPlaceDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Picks")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Curated favorites for you and your pup")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Nearby Favorites Section (Hidden until location access is enabled)
                    // if !curatedPlacesManager.getNearbyFavorites().isEmpty {
                    //     CuratedPlacesSection(
                    //         title: "Nearby Favorites",
                    //         subtitle: "Great spots within 30 miles",
                    //         places: curatedPlacesManager.getNearbyFavorites(),
                    //         onPlaceSelected: { place in
                    //             selectedPlace = place
                    //             showingPlaceDetail = true
                    //         }
                    //     )
                    // }
                    
                    // National Favorites Section (Vertical Layout)
                    CuratedPlacesVerticalSection(
                        title: "National Favorites",
                        subtitle: "Iconic dog-friendly destinations",
                        places: curatedPlacesManager.getNationalFavorites(),
                        onPlaceSelected: { place in
                            selectedPlace = place
                            showingPlaceDetail = true
                        }
                    )
                    
                    // Bottom padding
                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                updateUserLocation()
            }
            .onChange(of: locationManager.location) { _ in
                updateUserLocation()
            }
        }
        .sheet(isPresented: $showingPlaceDetail) {
            if let place = selectedPlace {
                CuratedPlaceDetailView(place: place)
            }
        }
    }
    
    private func updateUserLocation() {
        if let location = locationManager.location {
            curatedPlacesManager.updateUserLocation(location)
        }
    }
}

// MARK: - Curated Places Section (Horizontal)
struct CuratedPlacesSection: View {
    let title: String
    let subtitle: String
    let places: [CuratedPlace]
    let onPlaceSelected: (CuratedPlace) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            // Places ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(places) { place in
                        CuratedPlaceCard(place: place) {
                            onPlaceSelected(place)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Curated Places Vertical Section
struct CuratedPlacesVerticalSection: View {
    let title: String
    let subtitle: String
    let places: [CuratedPlace]
    let onPlaceSelected: (CuratedPlace) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            // Places Vertical List
            VStack(spacing: 16) {
                ForEach(places) { place in
                    CuratedPlaceVerticalCard(place: place) {
                        onPlaceSelected(place)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Curated Place Card (Horizontal)
struct CuratedPlaceCard: View {
    let place: CuratedPlace
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image with Gradient Overlay
                ZStack {
                    // Background Image
                    AsyncImage(url: URL(string: place.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                            
                            Image(systemName: place.type.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 280, height: 200)
                    .clipped()
                    
                    // Gradient Overlay
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.7)
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Content Overlay
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()
                        
                        // Place Name and Type
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            HStack(spacing: 8) {
                                // Type Pill
                                Text(place.type.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                    )
                                
                                Spacer()
                                
                                // Rating
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", place.rating))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Description
                            Text(place.description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .cornerRadius(16)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Curated Place Vertical Card
struct CuratedPlaceVerticalCard: View {
    let place: CuratedPlace
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Image
                AsyncImage(url: URL(string: place.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                        
                        Image(systemName: place.type.iconName)
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 120, height: 120)
                .clipped()
                .cornerRadius(12)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Name and Rating
                    HStack {
                        Text(place.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", place.rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Type
                    Text(place.type.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                    
                    // Description
                    Text(place.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    TopPicksView()
        .environmentObject(LocationManager())
}
