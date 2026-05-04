import SwiftUI
import CoreLocation

struct TopPicksView: View {
    @StateObject private var curatedPlacesManager = CuratedPlacesManager.shared
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedPlace: CuratedPlace?
    @State private var showingPlaceDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                PawPicksCuteBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Text("Paw Picks⭐")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.38))
                            Text("🐾")
                                .font(.title)
                        }
                        
                        Text("Handpicked dog-friendly spots from coast to coast")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.4, green: 0.32, blue: 0.45))
                            .fixedSize(horizontal: false, vertical: true)
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
                    
                    CuratedPlacesVerticalSection(
                        title: "Paw Picks⭐",
                        subtitle: "Tap a card to see more",
                        places: curatedPlacesManager.getNationalFavorites(),
                        onPlaceSelected: { place in
                            selectedPlace = place
                            showingPlaceDetail = true
                        }
                    )
                    
                    Spacer(minLength: 100)
                }
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

// MARK: - Cute pastel background

private struct PawPicksCuteBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.93, blue: 0.97),
                    Color(red: 0.93, green: 0.92, blue: 1.0),
                    Color(red: 1.0, green: 0.97, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color.pink.opacity(0.12))
                .frame(width: 180, height: 180)
                .offset(x: -120, y: -280)
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 140, height: 140)
                .offset(x: 150, y: 120)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundColor(.pink.opacity(0.14))
                .rotationEffect(.degrees(-18))
                .offset(x: 130, y: -240)
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundColor(.purple.opacity(0.12))
                .offset(x: -140, y: 80)
            Image(systemName: "star.fill")
                .font(.system(size: 18))
                .foregroundColor(.yellow.opacity(0.35))
                .offset(x: 40, y: -200)
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange.opacity(0.3))
                .offset(x: -80, y: -160)
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow.opacity(0.95), .orange.opacity(0.75))
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.32, green: 0.22, blue: 0.36))
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.42, green: 0.35, blue: 0.48))
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
                    CuratedPlaceRemoteImage(place: place, contentMode: .fill)
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
                            
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.95))
                                Text(place.displayLocationLine)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.92))
                                    .lineLimit(2)
                            }
                            
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
            HStack(alignment: .top, spacing: 14) {
                CuratedPlaceRemoteImage(place: place, contentMode: .fill)
                .frame(width: 118, height: 118)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                )
                .shadow(color: .pink.opacity(0.25), radius: 6, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(place.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.28, green: 0.2, blue: 0.32))
                            .lineLimit(2)
                        
                        Spacer(minLength: 8)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                            Text(String(format: "%.1f", place.rating))
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.5))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.9)))
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.pink)
                        Text(place.displayLocationLine)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(red: 0.42, green: 0.35, blue: 0.48))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.pink.opacity(0.14))
                    )
                    
                    Text(place.type.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.purple.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.12))
                        )
                    
                    Text(place.description)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.38, green: 0.34, blue: 0.42))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.pink.opacity(0.45), Color.purple.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.purple.opacity(0.12), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    TopPicksView()
        .environmentObject(LocationManager())
}
