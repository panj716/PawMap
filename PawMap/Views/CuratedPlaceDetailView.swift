import SwiftUI
import MapKit

struct CuratedPlaceDetailView: View {
    let place: CuratedPlace
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @State private var region: MKCoordinateRegion
    
    private var typeAccentColor: Color {
        switch place.type {
        case .dogFriendlyDistrict:
            return Color(red: 0.18, green: 0.68, blue: 0.62)
        default:
            return Color.green
        }
    }
    
    init(place: CuratedPlace) {
        self.place = place
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Image
                    CuratedPlaceRemoteImage(place: place, contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Header Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(place.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.pink)
                                    .font(.subheadline.weight(.semibold))
                                Text(place.displayLocationLine)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                // Type Badge
                                Text(place.type.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(typeAccentColor)
                                    )
                                
                                // Rating
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", place.rating))
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                
                                Spacer()
                            }
                        }
                        
                        // Description
                        Text(place.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Features
                        if !place.amenities.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Features")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(place.amenities, id: \.self) { amenity in
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            
                                            Text(amenity)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Map
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Map(coordinateRegion: $region, annotationItems: [place]) { place in
                                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)) {
                                    VStack {
                                        Image(systemName: place.type.iconName)
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(typeAccentColor)
                                            .clipShape(Circle())
                                        
                                        Text(place.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                        
                        // Address
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Address")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(place.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add to favorites functionality
                    }) {
                        Image(systemName: "heart")
                    }
                }
            }
        }
    }
}

#Preview {
    CuratedPlaceDetailView(place: CuratedPlace(
        id: "1",
        name: "Golden Gate Park",
        type: .park,
        address: "Golden Gate Park, San Francisco, CA 94117",
        locationLabel: "San Francisco, CA",
        latitude: 37.7694,
        longitude: -122.4862,
        imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Golden_Gate_Bridge_as_seen_from_Battery_East.jpg/960px-Golden_Gate_Bridge_as_seen_from_Battery_East.jpg",
        fallbackImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/California-06241_-_In_front_of_museum_%2820449897948%29.jpg/960px-California-06241_-_In_front_of_museum_%2820449897948%29.jpg",
        description: "A beautiful urban park perfect for dogs with plenty of space to run and play.",
        isNational: true,
        rating: 4.8,
        tags: ["dog-friendly", "outdoor", "nature"],
        amenities: ["Off-leash areas", "Water fountains", "Shaded paths"]
    ))
    .environmentObject(LocationManager())
}
