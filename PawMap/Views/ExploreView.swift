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
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                
                // Filter Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(
                            title: "全部",
                            isSelected: selectedType == nil,
                            action: { selectedType = nil }
                        )
                        
                        ForEach(Place.PlaceType.allCases, id: \.self) { type in
                            FilterButton(
                                title: type.displayName,
                                isSelected: selectedType == type,
                                action: { selectedType = type }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Places List
                List(filteredPlaces) { place in
                    SimplePlaceRow(place: place)
                }
            }
            .navigationTitle("探索")
        }
    }
    
    private var filteredPlaces: [Place] {
        var places = placesManager.places
        
        if let selectedType = selectedType {
            places = places.filter { $0.type == selectedType }
        }
        
        if !searchText.isEmpty {
            places = places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText) ||
                place.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return places
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索地点...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct FilterButton: View {
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

struct SimplePlaceRow: View {
    let place: Place
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(place.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(place.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack {
                Text(String(format: "%.1f", place.rating))
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(place.type.displayName)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
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