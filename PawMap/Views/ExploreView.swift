import Foundation
import CoreLocation
import MapKit
import SwiftUI  

struct ExploreView: View {
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    @State private var searchText = ""
    @State private var selectedType: Place.PlaceType?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .onChange(of: searchText) { newValue in
                        placesManager.searchPlaces(query: newValue)
                    }
                
                // 类型筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "全部",
                            isSelected: selectedType == nil
                        ) {
                            selectedType = nil
                            placesManager.filterPlaces(by: nil)
                        }
                        
                        ForEach(Place.PlaceType.allCases, id: \.self) { type in
                            FilterChip(
                                title: type.displayName,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                                placesManager.filterPlaces(by: type)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // 地点列表
                List(placesManager.filteredPlaces) { place in
                    PlaceRowView(place: place)
                        .onTapGesture {
                            placesManager.selectedPlace = place
                        }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("探索")
        }
        .sheet(item: $placesManager.selectedPlace) { place in
            PlaceDetailView(place: place)
        }
        .onAppear {
            placesManager.filterPlaces(by: selectedType)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索地点...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

struct PlaceRowView: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(Color(place.type.color))
                    .frame(width: 40, height: 40)
                
                Image(systemName: place.type.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
            }
            
            // 地点信息
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
                    
                    if place.isAutoLoaded {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                            Text("互联网")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExploreView()
        .environmentObject(PlacesManager())
        .environmentObject(UserManager())
}
