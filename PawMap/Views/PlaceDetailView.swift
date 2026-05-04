import Foundation
import CoreLocation
import MapKit
import SwiftUI


struct PlaceDetailView: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddReview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(place.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                userManager.toggleFavorite(placeId: place.id)
                            }) {
                                Image(systemName: userManager.isFavorite(placeId: place.id) ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(userManager.isFavorite(placeId: place.id) ? .red : .gray)
                            }
                        }
                        
                        HStack {
                            Image(systemName: place.type.iconName)
                                .foregroundColor(placeColor(for: place.type))
                            Text(place.type.displayName)
                                .font(.headline)
                                .foregroundColor(placeColor(for: place.type))
                        }
                    }
                    
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text(String(format: "%.1f", place.rating))
                            .font(.headline)
                        Text("(0 reviews)") // TODO: Load reviews from Firebase
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                        Text(place.address)
                            .font(.body)
                    }
                    
                    PlaceTagChipsSection(tags: place.tags, sectionTitle: "Tags", cardStyle: false)
                    
                    if !place.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(place.notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Reviews")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Add review") {
                                showingAddReview = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if true { // place.reviews.isEmpty { // TODO: Load reviews from Firebase
                            Text("No reviews yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            // ForEach(place.reviews) { review in
                            //     ReviewRow(review: review)
                            // }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "map")
                                Text("Open in Maps")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        if userManager.isLoggedIn {
                            Button(action: {
                                showingAddReview = true
                            }) {
                                HStack {
                                    Image(systemName: "star")
                                    Text("Add review")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(place: place)
        }
    }
    
    private func openInMaps() {
        let coordinate = place.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

/// Tag chips for place detail (full screen or map card).
struct PlaceTagChipsSection: View {
    let tags: [String]
    var sectionTitle: String = "Tags"
    var cardStyle: Bool = false
    
    var body: some View {
        Group {
            if !tags.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(sectionTitle)
                        .font(cardStyle ? .system(size: 15, weight: .bold, design: .rounded) : .headline)
                        .foregroundColor(cardStyle ? Color(red: 0.2, green: 0.2, blue: 0.2) : .primary)
                    
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: cardStyle ? 88 : 100), spacing: 8)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(tags, id: \.self) { raw in
                            Text(Place.displayLabel(forTag: raw))
                                .font(.system(size: cardStyle ? 11 : 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(chipBackground(for: raw))
                                .foregroundColor(chipForeground(for: raw))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(chipStroke(for: raw), lineWidth: raw == "needsReview" ? 1 : 0)
                                )
                        }
                    }
                }
            }
        }
    }
    
    private func chipBackground(for raw: String) -> Color {
        if raw == "needsReview" {
            return Color.orange.opacity(cardStyle ? 0.22 : 0.18)
        }
        if cardStyle {
            return Color(red: 1.0, green: 0.7, blue: 0.4).opacity(0.2)
        }
        return Color.blue.opacity(0.12)
    }
    
    private func chipForeground(for raw: String) -> Color {
        if raw == "needsReview" { return .orange }
        if cardStyle {
            return Color(red: 0.35, green: 0.25, blue: 0.22)
        }
        return Color.blue.opacity(0.95)
    }
    
    private func chipStroke(for raw: String) -> Color {
        raw == "needsReview" ? Color.orange.opacity(0.6) : .clear
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
    PlaceDetailView(place: Place(
        name: "Belle Isle Park",
        type: .park,
        address: "Belle Isle, Detroit, MI",
        latitude: 42.3389,
        longitude: -82.9967,
        rating: 4.5,
        tags: ["Outdoor", "Spacious", "Waterfront"],
        notes: "Scenic island park with a dedicated dog area.",
        createdBy: "system"
    ))
    .environmentObject(UserManager())
    .environmentObject(PlacesManager())
}
