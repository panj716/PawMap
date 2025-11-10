import SwiftUI
import MapKit

struct CuratedPlaceDetailView: View {
    let place: CuratedPlace
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @State private var region: MKCoordinateRegion
    
    init(place: CuratedPlace) {
        self.place = place
        // 使用统一的缩放级别，确保所有地点都使用相同的缩放比例
        // latitudeDelta 和 longitudeDelta 越大，地图显示的范围越大（zoom out）
        // 使用 0.05 可以获得一个适中的视图，显示地点及其周围区域
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Image
                    AsyncImage(url: URL(string: place.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                            
                            Image(systemName: place.type.iconName)
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 250)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Header Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(place.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
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
                                            .fill(Color.green)
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
                                            .background(Color.green)
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
        address: "Golden Gate Park, San Francisco, CA",
        latitude: 37.7694,
        longitude: -122.4862,
        imageURL: "https://example.com/image.jpg",
        description: "A beautiful urban park perfect for dogs with plenty of space to run and play.",
        isNational: true,
        rating: 4.8,
        tags: ["dog-friendly", "outdoor", "nature"],
        amenities: ["Off-leash areas", "Water fountains", "Shaded paths"]
    ))
    .environmentObject(LocationManager())
}
