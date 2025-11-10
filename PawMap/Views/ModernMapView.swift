import SwiftUI
import MapKit

struct ModernPlaceAnnotation: View {
    let place: Place
    let userManager: UserManager
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Larger, more prominent circular pin
                Circle()
                    .fill(placeTypeColor)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                
                // White icon inside the pin
                Image(systemName: place.type.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            
            // Favorite marker (smaller, positioned better)
            if userManager.isFavorite(placeId: place.id) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 10))
                    .offset(y: -8)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)
                    )
            }
            
            // Auto-loaded marker (smaller, positioned better)
            // if place.isAutoLoaded { // Commented out - not in current Place model
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .font(.system(size: 8))
                    .offset(x: 15, y: -8)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                    )
            // } // Commented out - not in current Place model
        }
    }
    
    // Enhanced colors for different place types
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

struct ModernMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedFilter: Place.PlaceType?
    @State private var selectedPlace: Place?
    @State private var showingPlaceDetail = false
    @State private var showingCategoryList = false
    @State private var searchText = ""
    @State private var showingWeather = true
    @State private var isUserInteracting = false
    @State private var lastZoomLevel: Double = 0.3
    
    // Weather data (simulated)
    @State private var currentWeather = "Sunny"
    @State private var temperature = 72
    
    var filteredPlaces: [Place] {
        let places = if let filter = selectedFilter {
            placesManager.places.filter { $0.type == filter }
        } else {
            placesManager.places
        }
        return places
    }
    
    var body: some View {
        ZStack {
            // Map Background
            if #available(iOS 17.0, *) {
                Map(position: $locationManager.mapCameraPosition, interactionModes: .all) {
                    UserAnnotation()
                    
                    ForEach(filteredPlaces) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            Button(action: {
                                handlePlaceSelection(place)
                            }) {
                                ModernPlaceAnnotation(place: place, userManager: userManager)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(8) // Increase tap area
                        }
                        .tag(place.id)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .tint(.green)
                .onMapCameraChange { context in
                    let currentZoom = context.region.span.latitudeDelta
                    let zoomChanged = abs(currentZoom - lastZoomLevel) > 0.001
                    
                    locationManager.mapCameraPosition = .region(context.region)
                    
                    if locationManager.isFollowingUser {
                        let distance = CLLocation(latitude: context.region.center.latitude, longitude: context.region.center.longitude)
                            .distance(from: CLLocation(latitude: locationManager.region.center.latitude, longitude: locationManager.region.center.longitude))
                        
                        if distance > 10 || zoomChanged {
                            locationManager.stopFollowingUser()
                        }
                    }
                    
                    lastZoomLevel = currentZoom
                }
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            // Only hide detail if tapping on blank areas (not on annotations)
                            // This will be called but we check if we're actually closing
                            if showingPlaceDetail && !showingCategoryList {
                                // Small delay to ensure annotation tap has priority
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if showingPlaceDetail {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedPlace = nil
                                            showingPlaceDetail = false
                                        }
                                    }
                                }
                            }
                        }
                )
            }
            
            VStack(spacing: 0) {
                // Top Search Bar (Instagram Style)
                HStack(spacing: 12) {
                    // Profile Button
                    Button(action: {}) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.7, blue: 0.4), Color(red: 0.9, green: 0.4, blue: 0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Search Bar (Instagram style - rounded, soft)
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 14))
                        
                        TextField("搜索狗狗友好的地方...", text: $searchText)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .background(Color(red: 0.98, green: 0.96, blue: 0.88).opacity(0.95))
                
                // Filter Toggles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterToggle(
                            title: "Coffee Shops",
                            icon: "cup.and.saucer.fill",
                            isSelected: selectedFilter == .coffee,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .coffee ? nil : .coffee
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        FilterToggle(
                            title: "Parks",
                            icon: "tree.fill",
                            isSelected: selectedFilter == .park,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .park ? nil : .park
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        FilterToggle(
                            title: "Trails",
                            icon: "figure.hiking",
                            isSelected: selectedFilter == .trail,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .trail ? nil : .trail
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        FilterToggle(
                            title: "Camps",
                            icon: "tent.fill",
                            isSelected: selectedFilter == .camp,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .camp ? nil : .camp
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        FilterToggle(
                            title: "Beaches",
                            icon: "umbrella.beach.fill",
                            isSelected: selectedFilter == .beach,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .beach ? nil : .beach
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        FilterToggle(
                            title: "Restaurants",
                            icon: "fork.knife",
                            isSelected: selectedFilter == .restaurant,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .restaurant ? nil : .restaurant
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        FilterToggle(
                            title: "Others",
                            icon: "ellipsis.circle.fill",
                            isSelected: selectedFilter == .other,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .other ? nil : .other
                                selectedFilter = newFilter
                                if newFilter != nil {
                                    withAnimation(.spring()) {
                                        showingCategoryList = true
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showingCategoryList = false
                                    }
                                }
                            }
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 12)
                
                Spacer()
                
                // Weather Widget and Location Button (Bottom Left - Instagram Style)
                VStack(spacing: 12) {
                    if showingWeather {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: weatherIcon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.7, blue: 0.4), Color(red: 0.9, green: 0.4, blue: 0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text(currentWeather)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                            }
                            
                            Text("\(temperature)°")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    }
                    
                    // Location Button (Instagram Style)
                    Button(action: {
                        print("Location button tapped")
                        locationManager.centerOnUserLocation()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("我的位置")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.4), Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    }
                }
                .padding(.leading, 16)
                .padding(.bottom, 120)
            }
            
            // Place Detail Card (Right Side)
            if let place = selectedPlace, showingPlaceDetail {
                HStack {
                    Spacer()
                    
                    PlaceDetailCard(place: place, userManager: userManager) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedPlace = nil
                            showingPlaceDetail = false
                        }
                    }
                    .frame(width: 320)
                    .padding(.trailing, 16)
                    .padding(.top, 140)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                    ))
                    .animation(.easeInOut(duration: 0.4), value: showingPlaceDetail)
                }
            }
            
            // Category Places List (Bottom Sheet)
            if showingCategoryList, let filter = selectedFilter {
                VStack {
                    Spacer()
                    
                    CategoryPlacesListView(
                        places: filteredPlaces,
                        category: filter,
                        selectedPlace: $selectedPlace,
                        showingPlaceDetail: $showingPlaceDetail,
                        isPresented: $showingCategoryList
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showingCategoryList)
                }
            }
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.88)) // Instagram style light yellow background
        .ignoresSafeArea(.all)
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
    
    private var weatherIcon: String {
        switch currentWeather.lowercased() {
        case "sunny": return "sun.max.fill"
        case "rainy": return "cloud.rain.fill"
        case "cloudy": return "cloud.fill"
        default: return "sun.max.fill"
        }
    }
    
    // Handle place selection from map annotation
    private func handlePlaceSelection(_ place: Place) {
        // Close category list if open
        if showingCategoryList {
            withAnimation(.spring(response: 0.2)) {
                showingCategoryList = false
            }
            // Small delay to allow list to close before opening detail
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.selectedPlace = place
                    self.showingPlaceDetail = true
                }
            }
        } else {
            // Direct selection if no list is open
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.selectedPlace = place
                self.showingPlaceDetail = true
            }
        }
    }
}

struct FilterToggle: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.3, blue: 0.3))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.4),
                                Color(red: 0.9, green: 0.4, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white
                    }
                }
            )
            .cornerRadius(20)
            .shadow(
                color: isSelected ? Color.black.opacity(0.15) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct PlaceDetailCard: View {
    let place: Place
    let userManager: UserManager
    @State private var selectedTab = 0
    let onClose: () -> Void
    @StateObject private var contentManager = UserContentManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Image with Close Button (Instagram Style)
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.4),
                            Color(red: 1.0, green: 0.6, blue: 0.5),
                            Color(red: 0.9, green: 0.4, blue: 0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .overlay(
                    ZStack {
                        VStack {
                            Image(systemName: placeIcon)
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text(place.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Close button in top-right corner
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    onClose()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white.opacity(0.8))
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 12)
                                .padding(.top, 8)
                            }
                            Spacer()
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 12) {
                // Title and Save Button (Instagram Style)
                HStack {
                    Text(place.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    Spacer()
                    
                    Button(action: {
                        userManager.toggleFavorite(placeId: place.id)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: userManager.isFavorite(placeId: place.id) ? "heart.fill" : "heart")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("保存")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.4),
                                    Color(red: 0.9, green: 0.4, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                }
                
                // Dog-friendly status (Instagram Style)
                HStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.7, blue: 0.4), Color(red: 0.9, green: 0.4, blue: 0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("狗狗友好")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                }
                
                // Location (Instagram Style)
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(place.address)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                }
                
                // Restaurant Seating Type (Instagram Style - only for restaurants)
                if place.type == .restaurant, let seatingType = place.restaurantSeatingType {
                    HStack(spacing: 8) {
                        Image(systemName: seatingType.iconName)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.7, blue: 0.4), Color(red: 0.9, green: 0.4, blue: 0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("\(seatingType.displayName) / \(seatingType.englishName)")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    }
                }
                
                // Action Buttons (Instagram Style)
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "tree.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("附近")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("导航")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.4),
                                    Color(red: 0.9, green: 0.4, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                }
                
                // Tabs (Instagram Style)
                HStack(spacing: 24) {
                    TabButton(title: "详情", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "评价", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "照片", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    
                    TabButton(title: "评分", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.top, 12)
                
                // Tab Content (Instagram Style)
                if selectedTab == 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        if !place.notes.isEmpty {
                            Text(place.notes)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                .lineSpacing(4)
                        } else {
                            Text("暂无详情")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                } else if selectedTab == 1 {
                    // VStack(alignment: .leading, spacing: 8) {
                    //     ForEach(place.reviews.prefix(3)) { review in
                    //         ReviewRow(review: review)
                    //     }
                    // }
                    // .frame(maxWidth: .infinity, alignment: .leading)
                    Text("暂无评价")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } else if selectedTab == 2 {
                    Text("照片即将推出")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } else {
                    UserContentView(place: place)
                        .environmentObject(userManager)
                        .environmentObject(contentManager)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
    }
    
    private var placeIcon: String {
        switch place.type {
        case .park: return "tree.fill"
        case .trail: return "figure.hiking"
        case .beach: return "umbrella.beach.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .shop: return "bag.fill"
        case .camp: return "tent.fill"
        case .restaurant: return "fork.knife"
        case .other: return "mappin.circle.fill"
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.gray.opacity(0.6))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.4),
                                Color(red: 0.9, green: 0.4, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .opacity(isSelected ? 1 : 0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct ReviewRow: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(review.userName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(review.comment)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModernMapView()
        .environmentObject(LocationManager())
        .environmentObject(PlacesManager())
        .environmentObject(UserManager())
}
