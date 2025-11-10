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
                        icon: "umbrella.beach.fill",
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
            }
            
            Spacer()
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
            
            Text("还没有想带\(userManager.currentUser?.dogName ?? "我的狗狗")去的地方")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("在地图上探索并收藏你想带狗狗去的地方")
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
                .fill(Color(place.type.color).opacity(0.3))
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
            // 类型图标
            ZStack {
                Circle()
                    .fill(Color(place.type.color))
                    .frame(width: 50, height: 50)
                
                Image(systemName: place.type.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
            }
            
            // 地点信息
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
                        .foregroundColor(Color(place.type.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(place.type.color).opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // 取消收藏按钮
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

#Preview {
    FavoritesView()
        .environmentObject(UserManager())
        .environmentObject(PlacesManager())
}
