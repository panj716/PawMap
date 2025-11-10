import SwiftUI
import MapKit

struct CategoryPlacesListView: View {
    let places: [Place]
    let category: Place.PlaceType
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var userManager: UserManager
    @Binding var selectedPlace: Place?
    @Binding var showingPlaceDetail: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header (Instagram Style)
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    Text("\(places.count) 个地点")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
                
                Spacer()
                
                Button("关闭") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)
            
            // Places list
            if places.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.4).opacity(0.5),
                                    Color(red: 0.9, green: 0.4, blue: 0.6).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("附近没有\(category.displayName)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    
                    Text("尝试扩大搜索范围或选择其他分类")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(places) { place in
                            CategoryPlaceRowView(
                                place: place,
                                onTap: {
                                    selectedPlace = place
                                    showingPlaceDetail = true
                                    isPresented = false
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
    }
}

struct CategoryPlaceRowView: View {
    let place: Place
    let onTap: () -> Void
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Place icon
                ZStack {
                    Circle()
                        .fill(placeTypeColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: place.type.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                }
                
                // Place info (Instagram Style)
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .lineLimit(1)
                    
                    Text(place.address)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack(spacing: 14) {
                        // Rating
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.4))
                                .font(.system(size: 12, weight: .semibold))
                            
                            Text(String(format: "%.1f", place.rating))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        }
                        
                        // Distance
                        if let userLocation = locationManager.location {
                            let distance = place.distance(from: userLocation)
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Text(String(format: "%.1f km", distance))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Favorite indicator
                if userManager.isFavorite(placeId: place.id) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeTypeColor: Color {
        switch place.type {
        case .coffee:
            return Color.orange
        case .trail:
            return Color.green
        case .park:
            return Color.blue
        case .beach:
            return Color.cyan
        case .shop:
            return Color.purple
        case .camp:
            return Color.brown
        case .restaurant:
            return Color.red
        case .other:
            return Color.gray
        }
    }
}

// Extension for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    CategoryPlacesListView(
        places: [
            Place(
                id: "1",
                name: "星巴克",
                type: .coffee,
                address: "123 Main St, Ann Arbor, MI",
                latitude: 42.2796,
                longitude: -83.7462,
                rating: 4.5,
                tags: ["dogFriendly"],
                notes: "Dog friendly coffee shop",
                createdBy: "user",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                reportCount: 0,
                images: []
            )
        ],
        category: .coffee,
        selectedPlace: .constant(nil),
        showingPlaceDetail: .constant(false),
        isPresented: .constant(true)
    )
    .environmentObject(LocationManager())
    .environmentObject(UserManager())
}
