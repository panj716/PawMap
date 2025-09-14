import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @State private var selectedPlace: Place?
    
    var favoritePlaces: [Place] {
        placesManager.places.filter { place in
            userManager.isFavorite(placeId: place.id)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if favoritePlaces.isEmpty {
                    EmptyFavoritesView()
                } else {
                    List(favoritePlaces) { place in
                        FavoritePlaceRow(place: place)
                            .onTapGesture {
                                selectedPlace = place
                            }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("我想带\(userManager.currentUser?.dogName ?? "我的狗狗")去的地方")
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
