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

/// Map pin for curated “dog-friendly district” entries (teal, distinct from single-place pins).
private struct CuratedDogFriendlyDistrictMapPin: View {
    private let pinColor = Color(red: 0.18, green: 0.68, blue: 0.62)
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.32), radius: 4, x: 0, y: 2)
                Image(systemName: "building.2.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .offset(x: 12, y: 12)
            }
            Text("District")
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(pinColor)
        }
    }
}

struct ModernMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var placeViewModel: PlaceViewModel  // Changed from PlacesManager to PlaceViewModel
    @EnvironmentObject var userManager: UserManager
    @ObservedObject private var curatedPlacesManager = CuratedPlacesManager.shared
    
    @State private var selectedFilter: Place.PlaceType?
    @State private var selectedPlace: Place?
    @State private var showingPlaceDetail = false
    @State private var selectedCuratedPlace: CuratedPlace?
    @State private var showingCategoryList = false
    @State private var zipcodeText = ""
    @State private var zipcodeErrorMessage: String?
    @State private var showingZipcodeResults = false
    @State private var showingWeather = true
    @State private var isUserInteracting = false
    @State private var lastZoomLevel: Double = 0.3
    
    // Weather data (simulated)
    @State private var currentWeather = "Sunny"
    @State private var temperature = 72
    
    var filteredPlaces: [Place] {
        // Use placeViewModel.filteredPlaces which comes from Firebase
        // This will automatically update when new places are added to Firebase
        return placeViewModel.filteredPlaces
    }
    
    private var dogFriendlyDistrictPins: [CuratedPlace] {
        curatedPlacesManager.curatedPlaces.filter { $0.type == .dogFriendlyDistrict }
    }
    
    var body: some View {
        ZStack {
            // Map Background
            if #available(iOS 17.0, *) {
                Map(position: $locationManager.mapCameraPosition, interactionModes: .all) {
                    // Places render in the lower map overlay level so dog-friendly district pins can sit on top.
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
                        .mapOverlayLevel(level: .aboveRoads)
                    }
                    ForEach(dogFriendlyDistrictPins) { curated in
                        Annotation(curated.name, coordinate: curated.coordinate) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedPlace = nil
                                    showingPlaceDetail = false
                                }
                                selectedCuratedPlace = curated
                            } label: {
                                CuratedDogFriendlyDistrictMapPin()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(8)
                        }
                        .tag("curated-\(curated.id)")
                        .mapOverlayLevel(level: .aboveLabels)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .tint(.green)
                .onAppear {
                    fitCuratedDistrictPinsIfNearCurrentView()
                }
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
                        
                        TextField("Enter ZIP code (e.g. 10001)", text: $zipcodeText)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                            .keyboardType(.numberPad)
                            .onSubmit {
                                searchByZipcode()
                            }
                        
                        Button(action: {
                            searchByZipcode()
                        }) {
                            Text("Go")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pink)
                        }
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

                if let zipcodeErrorMessage {
                    Text(zipcodeErrorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
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
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                            icon: "beach.umbrella.fill",
                            isSelected: selectedFilter == .beach,
                            action: { 
                                let newFilter: Place.PlaceType? = selectedFilter == .beach ? nil : .beach
                                selectedFilter = newFilter
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                                placeViewModel.setFilter(newFilter) // Sync with PlaceViewModel
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
                
                // Weather + dog-friendly district map controls (Bottom Left)
                VStack(spacing: 12) {
                    if !dogFriendlyDistrictPins.isEmpty {
                        Button {
                            fitMapToAllCuratedDogDistricts()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 0.12, green: 0.55, blue: 0.5))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Dog-friendly districts")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    Text("Teal pins — tap to zoom")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.22))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: 220)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color(red: 0.18, green: 0.68, blue: 0.62).opacity(0.35), radius: 10, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
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
            if showingZipcodeResults {
                VStack {
                    Spacer()

                    ZipcodePlacesListView(
                        places: filteredPlaces,
                        selectedPlace: $selectedPlace,
                        showingPlaceDetail: $showingPlaceDetail,
                        isPresented: $showingZipcodeResults
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showingZipcodeResults)
                }
            } else if showingCategoryList, let filter = selectedFilter {
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
        .sheet(item: $selectedCuratedPlace) { curated in
            CuratedPlaceDetailView(place: curated)
                .environmentObject(locationManager)
        }
    }
    
    /// Zoom map so every curated dog-friendly district pin is visible (teal pins).
    private func fitMapToAllCuratedDogDistricts() {
        let pins = dogFriendlyDistrictPins
        guard !pins.isEmpty else { return }
        let coords = pins.map(\.coordinate)
        let fitted = MKCoordinateRegion(boundingCoordinates: coords, paddingFraction: 0.22)
        withAnimation(.easeInOut(duration: 0.45)) {
            locationManager.applyMapRegion(fitted)
        }
    }
    
    /// If district pins sit just outside the opening viewport but the user is still “regional,” nudge the camera once.
    private func fitCuratedDistrictPinsIfNearCurrentView() {
        let pins = dogFriendlyDistrictPins
        guard !pins.isEmpty else { return }
        let r = locationManager.region
        if pins.contains(where: { r.containsMapCoordinate($0.coordinate) }) { return }
        let mapCtr = CLLocation(latitude: r.center.latitude, longitude: r.center.longitude)
        let minDist = pins.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: mapCtr) }.min() ?? .infinity
        guard minDist < 260_000 else { return }
        fitMapToAllCuratedDogDistricts()
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
        selectedCuratedPlace = nil
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

    private func searchByZipcode() {
        let trimmed = zipcodeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            zipcodeErrorMessage = "Please enter a ZIP code"
            return
        }
        print("📮 [ZipSearch] Searching zipcode: \(trimmed)")

        let geocoder = CLGeocoder()
        zipcodeErrorMessage = nil
        geocoder.geocodeAddressString(trimmed) { placemarks, error in
            DispatchQueue.main.async {
                guard error == nil, let coordinate = placemarks?.first?.location?.coordinate else {
                    print("❌ [ZipSearch] Geocode failed for \(trimmed): \(error?.localizedDescription ?? "unknown error")")
                    zipcodeErrorMessage = "Couldn’t find that ZIP code. Try again."
                    return
                }
                print("✅ [ZipSearch] Geocoded \(trimmed) -> (\(coordinate.latitude), \(coordinate.longitude))")

                // Clear category filter so zipcode results are not accidentally empty.
                selectedFilter = nil
                showingCategoryList = false
                placeViewModel.setFilter(nil)

                placeViewModel.setZipcodeSearch(center: coordinate, radiusMiles: 10.0)
                locationManager.setRegion(to: coordinate, animated: true)
                print("🧭 [ZipSearch] Results count after filter: \(placeViewModel.filteredPlaces.count)")
                withAnimation(.spring()) {
                    showingZipcodeResults = true
                }
            }
        }
    }
}

struct ZipcodePlacesListView: View {
    let places: [Place]
    @Binding var selectedPlace: Place?
    @Binding var showingPlaceDetail: Bool
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Places within 10 mi")
                    .font(.headline)
                Spacer()
                Text("\(places.count) places")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Collapse") {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if places.isEmpty {
                VStack(spacing: 8) {
                    Text("No places within 10 mi of this ZIP")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(places) { place in
                    Button(action: {
                        selectedPlace = place
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingPlaceDetail = true
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(place.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(String(format: "%.1f★", place.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -2)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
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
                            Text("Save")
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
                    
                    Text("Dog-friendly")
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
                
                PlaceTagChipsSection(tags: place.tags, sectionTitle: "Tags", cardStyle: true)
                
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
                            Text("Nearby")
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
                            Text("Directions")
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
                    TabButton(title: "Details", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Reviews", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "Photos", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    
                    TabButton(title: "Ratings", isSelected: selectedTab == 3) {
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
                            Text("No details yet")
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
                    Text("No reviews yet")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } else if selectedTab == 2 {
                    Text("Photos coming soon")
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
        case .beach: return "beach.umbrella.fill"
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

// MARK: - Map region helpers (curated district visibility)

private extension MKCoordinateRegion {
    func containsMapCoordinate(_ coord: CLLocationCoordinate2D) -> Bool {
        let halfLat = span.latitudeDelta / 2
        let halfLon = span.longitudeDelta / 2
        return abs(coord.latitude - center.latitude) <= halfLat
            && abs(coord.longitude - center.longitude) <= halfLon
    }
    
    /// Smallest region containing all coordinates, with extra margin for pin tap targets.
    init(boundingCoordinates coords: [CLLocationCoordinate2D], paddingFraction: Double) {
        guard let first = coords.first else {
            self.init(
                center: CLLocationCoordinate2D(latitude: 42.39, longitude: -83.50),
                span: MKCoordinateSpan(latitudeDelta: 0.42, longitudeDelta: 0.58)
            )
            return
        }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for c in coords.dropFirst() {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let cLat = (minLat + maxLat) / 2
        let cLon = (minLon + maxLon) / 2
        var latD = max((maxLat - minLat) * (1 + paddingFraction), 0.06)
        var lonD = max((maxLon - minLon) * (1 + paddingFraction), 0.06)
        latD = min(latD, 40)
        lonD = min(lonD, 40)
        self.init(center: CLLocationCoordinate2D(latitude: cLat, longitude: cLon), span: MKCoordinateSpan(latitudeDelta: latD, longitudeDelta: lonD))
    }
}

#Preview {
    ModernMapView()
        .environmentObject(LocationManager())
        .environmentObject(PlaceViewModel())
        .environmentObject(UserManager())
}
