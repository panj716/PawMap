import SwiftUI
import MapKit

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

struct ModernMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    
    @Binding var selectedFilter: Place.PlaceType?
    @State private var selectedPlace: Place?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 44.3148, longitude: -85.6024),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 44.3148, longitude: -85.6024),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var isUserInteracting = false
    @State private var lastZoomLevel: Double = 0.1
    
    var filteredPlaces: [Place] {
        let places = if let filter = selectedFilter {
            placesManager.places.filter { $0.type == filter }
        } else {
            placesManager.places
        }
        print("🔥 Filtered places count: \(places.count)")
        for place in places.prefix(3) {
            print("🔥   - \(place.name) at \(place.coordinate)")
        }
        return places
    }
    
    var body: some View {
        ZStack {
            // 使用新的Map API (iOS 17+)
            if #available(iOS 17.0, *) {
                Map(position: $locationManager.mapCameraPosition, interactionModes: .all) {
                    // 用户位置 - 总是显示，让MapKit处理
                    UserAnnotation()
                    
                    // 地点标注
                    ForEach(filteredPlaces) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            ModernPlaceAnnotation(place: place, userManager: userManager)
                                .onTapGesture {
                                    print("🔥 TAPPED ON PLACE: \(place.name)")
                                    print("🔥 Place notes: \(place.notes)")
                                    print("🔥 Setting selectedPlace to: \(place.name)")
                                    selectedPlace = place
                                    print("🔥 selectedPlace is now: \(selectedPlace?.name ?? "nil")")
                                }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .tint(.pink)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                    MapPitchToggle()
                }
                .onMapCameraChange { context in
                    // Track zoom level for Google Maps-like behavior
                    let currentZoom = context.region.span.latitudeDelta
                    let zoomChanged = abs(currentZoom - lastZoomLevel) > 0.001
                    
                    // Update region immediately for responsive feel
                    mapRegion = context.region
                    locationManager.mapCameraPosition = .region(context.region)
                    
                    // Enhanced user interaction detection
                    if locationManager.isFollowingUser {
                        let distance = CLLocation(latitude: context.region.center.latitude, longitude: context.region.center.longitude)
                            .distance(from: CLLocation(latitude: locationManager.region.center.latitude, longitude: locationManager.region.center.longitude))
                        
                        // Stop following if user moves map or zooms significantly
                        if distance > 10 || zoomChanged {
                            print("User manually interacted with map (moved \(distance)m, zoomed: \(zoomChanged)), stopping location following")
                            locationManager.stopFollowingUser()
                        }
                    }
                    
                    // Update zoom level tracking
                    if zoomChanged {
                        lastZoomLevel = currentZoom
                        isUserInteracting = true
                        
                        // Reset interaction flag after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isUserInteracting = false
                        }
                    }
                }
                .onAppear {
                    // Start following user location when map appears
                    if locationManager.authorizationStatus == .authorizedWhenInUse || 
                       locationManager.authorizationStatus == .authorizedAlways {
                        print("Map appeared with location permission, starting to follow user")
                        locationManager.startFollowingUser()
                    } else {
                        print("Map appeared but no location permission yet")
                    }
                }
                .overlay(alignment: .trailing) {
                    VStack(spacing: 8) {
                        // Center on User Location Button
                        Button(action: {
                            print("Center on user location button tapped")
                            locationManager.centerOnUserLocation()
                        }) {
                            Image(systemName: locationManager.isFollowingUser ? "location.fill" : "location")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: locationManager.isFollowingUser ? [Color.green, Color.green.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: (locationManager.isFollowingUser ? Color.green : Color.blue).opacity(0.3), radius: 4, x: 0, y: 2)
                                .scaleEffect(locationManager.isFollowingUser ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: locationManager.isFollowingUser)
                        }
                        
                        // Refresh Location Button
                        Button(action: {
                            locationManager.requestFreshLocation()
                        }) {
                            Image(systemName: "location.circle")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 100)
                }
            } else {
                // 兼容旧版本iOS
                Map(coordinateRegion: $locationManager.region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    userTrackingMode: .none,
                    annotationItems: filteredPlaces) { place in
                    MapAnnotation(coordinate: place.coordinate) {
                        ModernPlaceAnnotation(place: place, userManager: userManager)
                            .onTapGesture {
                                selectedPlace = place
                            }
                    }
                }
                .overlay(alignment: .trailing) {
                    VStack(spacing: 8) {
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 100)
                }
            }
        }
        .sheet(item: $selectedPlace) { place in
            ModernPlaceDetailView(place: place)
                .environmentObject(locationManager)
                .environmentObject(placesManager)
                .environmentObject(userManager)
        }
        .onChange(of: selectedFilter) {
            // 当筛选器改变时，可以调整地图视图
        }
    }
    
    // MARK: - Zoom Functions
}

struct ModernPlaceAnnotation: View {
    let place: Place
    let userManager: UserManager
    @State private var isPressed = false
    @State private var isPulsing = false
    
    // Different colors for each place type
    private var placeTypeColors: [Color] {
        switch place.type {
        case .coffee:
            return [Color.brown, Color.brown.opacity(0.8)]
        case .trail:
            return [Color.green, Color.green.opacity(0.8)]
        case .park:
            return [Color.green, Color.green.opacity(0.8)]
        case .beach:
            return [Color.blue, Color.cyan.opacity(0.8)]
        case .shop:
            return [Color.orange, Color.orange.opacity(0.8)]
        case .other:
            return [Color.purple, Color.purple.opacity(0.8)]
        }
    }
    
    private var shadowColor: Color {
        switch place.type {
        case .coffee: return .brown
        case .trail: return .green
        case .park: return .green
        case .beach: return .blue
        case .shop: return .orange
        case .other: return .purple
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: placeTypeColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isPressed ? 36 : 32, height: isPressed ? 36 : 32)
                    .shadow(color: shadowColor.opacity(0.4), radius: isPressed ? 5 : 3, x: 0, y: isPressed ? 3 : 2)
                    .scaleEffect(isPressed ? 1.1 : (isPulsing ? 1.05 : 1.0))
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                    .onAppear {
                        // Start pulsing animation after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
                            isPulsing = true
                        }
                    }
                
                // Custom beach icon for beaches
                if place.type == .beach {
                    VStack(spacing: 1) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 8))
                        Image(systemName: "wave.3.right")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                    }
                } else {
                    Image(systemName: place.type.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .onTapGesture {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
            
            // 收藏标记
            if userManager.isFavorite(placeId: place.id) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                    .offset(y: -4)
            }
    
            // 评分标记
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 8))
                Text(String(format: "%.1f", place.rating))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .offset(y: -8)
        }
    }
}

struct ModernPlaceDetailView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var placesManager: PlacesManager
    @State private var showingReportSheet = false
    @State private var showingAddReviewSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    PlaceDetailHeader(place: place, dismiss: dismiss)
                    
                    // Address
                    PlaceDetailAddress(place: place)
                    
                    // Rating
                    PlaceDetailRating(place: place)
                    
                    // Dog amenities
                    if hasAnyAmenities {
                        PlaceDetailAmenities(place: place)
                    }
                    
                    // Description
                    if !place.notes.isEmpty {
                        PlaceDetailDescription(place: place)
                    }
                    
                    // Photos
                    if !place.images.isEmpty {
                        PlaceDetailPhotos(place: place)
                    }
                    
                    // Reviews
                    if !place.reviews.isEmpty {
                        PlaceDetailReviews(place: place)
                    }
                    
                    // Action buttons
                    PlaceDetailActions(place: place, userManager: userManager, 
                                     showingAddReviewSheet: $showingAddReviewSheet,
                                     showingReportSheet: $showingReportSheet)
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportPlaceView(place: place)
                .environmentObject(placesManager)
                .environmentObject(userManager)
        }
        .sheet(isPresented: $showingAddReviewSheet) {
            AddReviewView(place: place)
                .environmentObject(placesManager)
                .environmentObject(userManager)
        }
    }
    
    private var hasAnyAmenities: Bool {
        place.dogAmenities.hasDogBowl || 
        !place.dogAmenities.allowsOffLeash || 
        place.dogAmenities.hasDogTreats || 
        place.dogAmenities.hasWaterStation ||
        place.dogAmenities.allowsOffLeash
    }
}

struct PlaceDetailHeader: View {
    let place: Place
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Category tag
                HStack {
                    let categoryIcon = place.type == .beach ? "🌊" : place.type == .coffee ? "☕️" : "🐕"
                    Text(categoryIcon)
                        .font(.caption)
                    Text(place.type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

struct PlaceDetailAddress: View {
    let place: Place
    
    var body: some View {
        HStack {
            Image(systemName: "mappin")
                .foregroundColor(.orange)
                .font(.caption)
            Text(place.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct PlaceDetailRating: View {
    let place: Place
    
    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(place.rating) ? "star.fill" : "star")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
            }
            Text(String(format: "%.1f", place.rating))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct PlaceDetailAmenities: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dog Amenities")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                if place.dogAmenities.hasDogBowl {
                    AmenityTag(text: "Water Bowl", color: .blue, icon: "drop")
                }
                if !place.dogAmenities.allowsOffLeash {
                    AmenityTag(text: "On-Leash Only", color: .orange, icon: "link")
                }
                if place.dogAmenities.hasDogTreats {
                    AmenityTag(text: "Dog Treats", color: .green, icon: "heart")
                }
                if place.dogAmenities.hasWaterStation {
                    AmenityTag(text: "Water Station", color: .blue, icon: "drop.circle")
                }
                if place.dogAmenities.allowsOffLeash {
                    AmenityTag(text: "Off-Leash OK", color: .green, icon: "link.badge.plus")
                }
            }
        }
    }
}

struct PlaceDetailDescription: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(place.notes)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PlaceDetailPhotos: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(place.images, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct PlaceDetailReviews: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reviews")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("(\(place.reviews.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(place.reviews.prefix(3), id: \.id) { review in
                ReviewRowView(review: review)
            }
            
            if place.reviews.count > 3 {
                Button("See all \(place.reviews.count) reviews") {
                    // Show all reviews
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
    }
}

struct PlaceDetailActions: View {
    let place: Place
    let userManager: UserManager
    @Binding var showingAddReviewSheet: Bool
    @Binding var showingReportSheet: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingAddReviewSheet = true
            }) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Rate & Review")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if userManager.isLoggedIn {
                        userManager.toggleFavorite(placeId: place.id)
                    }
                }) {
                    HStack {
                        Image(systemName: userManager.isFavorite(placeId: place.id) ? "heart.fill" : "heart")
                        Text(userManager.isLoggedIn ? (userManager.isFavorite(placeId: place.id) ? "Saved" : "Save") : "Login to Save")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showingReportSheet = true
                }) {
                    HStack {
                        Image(systemName: "flag")
                        Text("Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct AmenityTag: View {
    let text: String
    let color: Color
    let icon: String?
    
    init(text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(8)
    }
}

struct DogAmenitiesView: View {
    let amenities: DogAmenities
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("狗狗设施")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                AmenityRow(icon: "bowl.fill", title: "狗碗", isAvailable: amenities.hasDogBowl)
                AmenityRow(icon: "house.fill", title: "室内允许", isAvailable: amenities.hasIndoorAccess)
                AmenityRow(icon: "leaf.fill", title: "仅户外", isAvailable: amenities.isOutdoorOnly)
                AmenityRow(icon: "gift.fill", title: "狗零食", isAvailable: amenities.hasDogTreats)
                AmenityRow(icon: "drop.fill", title: "饮水站", isAvailable: amenities.hasWaterStation)
                AmenityRow(icon: "sun.max.fill", title: "遮阳", isAvailable: amenities.hasShade)
                AmenityRow(icon: "fence", title: "围栏区域", isAvailable: amenities.hasFencedArea)
                AmenityRow(icon: "figure.walk", title: "可松绳", isAvailable: amenities.allowsOffLeash)
                AmenityRow(icon: "trash.fill", title: "垃圾袋", isAvailable: amenities.hasWasteBags)
                AmenityRow(icon: "shower.fill", title: "狗狗洗澡", isAvailable: amenities.hasDogWash)
            }
        }
    }
}

struct AmenityRow: View {
    let icon: String
    let title: String
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isAvailable ? .green : .gray)
                .font(.system(size: 16))
            
            Text(title)
                .font(.caption)
                .foregroundColor(isAvailable ? .primary : .secondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isAvailable ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.user)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }
            }
            
            Text(review.comment)
                .font(.body)
                .foregroundColor(.secondary)
            
            // User photos
            if !review.userPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<review.userPhotos.count, id: \.self) { index in
                            if let data = Data(base64Encoded: review.userPhotos[index]),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack {
                Text(review.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if review.isHelpful > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        Text("\(review.isHelpful)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ReportPlaceView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedReason: PlaceReport.ReportReason = .inaccurateInfo
    @State private var description = ""
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("举报原因")) {
                    Picker("选择原因", selection: $selectedReason) {
                        ForEach(PlaceReport.ReportReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("详细描述")) {
                    TextField("请描述具体问题...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("提交举报") {
                        submitReport()
                    }
                    .disabled(description.isEmpty)
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("举报地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("举报已提交", isPresented: $showingSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("感谢您的反馈！我们会尽快处理这个举报。")
            }
        }
    }
    
    private func submitReport() {
        placesManager.reportPlace(
            placeId: place.id,
            reporterId: userManager.currentUser?.id ?? "anonymous",
            reporterName: userManager.currentUser?.name ?? "匿名用户",
            reason: selectedReason,
            description: description
        )
        showingSuccessAlert = true
    }
}

#Preview {
    ModernMapView(selectedFilter: .constant(nil))
        .environmentObject(LocationManager())
        .environmentObject(PlacesManager())
        .environmentObject(UserManager())
} 