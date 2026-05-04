import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @State private var selectedPlace: Place?
    @State private var selectedCategory: Place.PlaceType? = nil
    
    var favoritePlaces: [Place] {
        let allFavorites = placesManager.places.filter { place in
            userManager.isFavorite(placeId: place.id)
        }
        
        if let selectedCategory = selectedCategory {
            return allFavorites.filter { $0.type == selectedCategory }
        }
        return allFavorites
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {}) {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Favorites")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Category Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    CategoryFilterButton(
                        title: "All",
                        icon: "square.grid.2x2",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    CategoryFilterButton(
                        title: "Parks",
                        icon: "tree.fill",
                        isSelected: selectedCategory == .park,
                        action: { selectedCategory = .park }
                    )
                    
                    CategoryFilterButton(
                        title: "Trails",
                        icon: "figure.hiking",
                        isSelected: selectedCategory == .trail,
                        action: { selectedCategory = .trail }
                    )
                    
                    CategoryFilterButton(
                        title: "Beaches",
                        icon: "beach.umbrella.fill",
                        isSelected: selectedCategory == .beach,
                        action: { selectedCategory = .beach }
                    )
                    
                    CategoryFilterButton(
                        title: "Cafes",
                        icon: "cup.and.saucer.fill",
                        isSelected: selectedCategory == .coffee,
                        action: { selectedCategory = .coffee }
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            // Content
            if favoritePlaces.isEmpty {
                EmptyFavoritesView()
            } else {
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Horizontal featured favorites
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Favorites")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(favoritePlaces) { place in
                                        FavoritePlaceCard(place: place)
                                            .onTapGesture {
                                                selectedPlace = place
                                            }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Vertical list of all favorites
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Favorites")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(favoritePlaces) { place in
                                    FavoritePlaceRow(place: place)
                                        .padding(.horizontal, 20)
                                        .onTapGesture {
                                            selectedPlace = place
                                        }
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
    }
}

struct EmptyFavoritesView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No spots saved for \(userManager.currentUser?.dogName ?? "your dog") yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Explore the map and tap ❤️ to save places to visit")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.green.opacity(0.8) : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
    }
}

struct FavoritePlaceCard: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Place Image (placeholder for now)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 280, height: 160)
                
                if !place.images.isEmpty {
                    // If place has images, show the first one
                    AsyncImage(url: URL(string: place.images[0])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 160)
                            .clipped()
                    } placeholder: {
                        PlaceholderImageView(place: place)
                    }
                    .cornerRadius(12)
                } else {
                    PlaceholderImageView(place: place)
                }
            }
            
            // Place Info
            VStack(alignment: .leading, spacing: 8) {
                Text(place.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Dog-friendly")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Rating stars
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.system(size: 10))
                        }
                    }
                }
                
                // Tags/Amenities
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if place.dogAmenities.hasDogBowl {
                            TagView(text: "Water Bowl", color: .blue)
                        }
                        if place.dogAmenities.allowsOffLeash {
                            TagView(text: "Off-Leash", color: .green)
                        }
                        if place.dogAmenities.hasIndoorAccess {
                            TagView(text: "Indoor", color: .purple)
                        }
                        if place.dogAmenities.isOutdoorOnly {
                            TagView(text: "Outdoor", color: .orange)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 280)
    }
}

struct PlaceholderImageView: View {
    let place: Place
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(placeColor(for: place.type).opacity(0.3))
                .frame(width: 280, height: 160)
            
            VStack(spacing: 8) {
                Image(systemName: place.type.iconName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                
                Text(place.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .cornerRadius(12)
    }
}

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(8)
    }
}

struct FavoritePlaceRow: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(placeColor(for: place.type))
                    .frame(width: 50, height: 50)
                
                Image(systemName: place.type.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
            }
            
            // Place info
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
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
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(placeColor(for: place.type).opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Remove favorite
            Button(action: {
                userManager.toggleFavorite(placeId: place.id)
            }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
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
    FavoritesView()
        .environmentObject(UserManager())
        .environmentObject(PlacesManager())
}
