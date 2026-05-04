import SwiftUI
import PhotosUI
import CoreLocation
import Combine
import MapKit

struct AddPlaceSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var placesManager: PlacesManager // Keep for now for compatibility
    
    @State private var name = ""
    @State private var selectedType: Place.PlaceType = .other
    @State private var address = ""
    @State private var notes = ""
    @State private var rating: Double = 5.0
    @State private var dogAmenities = DogAmenities.empty
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var showingImagePicker = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var geocodingAddress = false
    
    // Map pin picker state
    @State private var useMapPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.2464, longitude: -83.7417),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var isReverseGeocoding = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Add a place")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Share a dog-friendly spot you discovered")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Basics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basics")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            TextField("Place name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("Type", selection: $selectedType) {
                                ForEach(Place.PlaceType.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.iconName)
                                        Text(type.displayName)
                                    }
                                    .tag(type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Address: map vs manual
                            HStack {
                                Button(action: {
                                    useMapPicker.toggle()
                                }) {
                                    HStack {
                                        Image(systemName: useMapPicker ? "mappin.circle.fill" : "text.cursor")
                                        Text(useMapPicker ? "Pick on map" : "Enter manually")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                            
                            if useMapPicker {
                                // Map picker
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Drag the map to the spot, then tap the button below")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    // Map
                                    ZStack(alignment: .center) {
                                        Map(coordinateRegion: Binding(
                                            get: { mapRegion },
                                            set: { newRegion in
                                                mapRegion = newRegion
                                                selectedCoordinate = newRegion.center
                                            }
                                        ), interactionModes: .all, showsUserLocation: true, userTrackingMode: .none)
                                        .frame(height: 250)
                                        .cornerRadius(12)
                                        
                                        // Center pin (target location)
                                        VStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.red)
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                            Spacer()
                                        }
                                        .frame(height: 250)
                                        .allowsHitTesting(false)
                                    }
                                    
                                    // Confirm location
                                    Button(action: {
                                        let coordinate = mapRegion.center
                                        selectedCoordinate = coordinate
                                        reverseGeocode(coordinate: coordinate)
                                    }) {
                                        HStack {
                                            if isReverseGeocoding {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "checkmark.circle.fill")
                                            }
                                            Text(isReverseGeocoding ? "Looking up address…" : "Use this location")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isReverseGeocoding ? Color.gray : Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isReverseGeocoding)
                                    
                                    if let coordinate = selectedCoordinate {
                                        HStack {
                                            Image(systemName: address.isEmpty ? "mappin.circle" : "mappin.circle.fill")
                                                .foregroundColor(address.isEmpty ? .orange : .green)
                                            Text(address.isEmpty ? "Location selected — tap the button above to fill the address" : "Location selected")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                TextField("Address (filled automatically)", text: $address)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true)
                            } else {
                                TextField("Address", text: $address)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            TextField("Description & notes", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    
                    // Rating
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your rating")
                            .font(.headline)
                        
                        HStack {
                            Text("Rating: \(String(format: "%.1f", rating))")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Button(action: {
                                        rating = Double(index + 1)
                                    }) {
                                        Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.title2)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Dog amenities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dog amenities")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            AmenityToggleRow(
                                icon: "bowl.fill",
                                title: "Water bowls",
                                isOn: $dogAmenities.hasDogBowl
                            )
                            
                            AmenityToggleRow(
                                icon: "house.fill",
                                title: "Dogs allowed inside",
                                isOn: $dogAmenities.hasIndoorAccess
                            )
                            
                            AmenityToggleRow(
                                icon: "leaf.fill",
                                title: "Outside only",
                                isOn: $dogAmenities.isOutdoorOnly
                            )
                            
                            AmenityToggleRow(
                                icon: "gift.fill",
                                title: "Treats",
                                isOn: $dogAmenities.hasDogTreats
                            )
                            
                            AmenityToggleRow(
                                icon: "drop.fill",
                                title: "Water station",
                                isOn: $dogAmenities.hasWaterStation
                            )
                            
                            AmenityToggleRow(
                                icon: "sun.max.fill",
                                title: "Shade",
                                isOn: $dogAmenities.hasShade
                            )
                            
                            AmenityToggleRow(
                                icon: "fence",
                                title: "Fenced area",
                                isOn: $dogAmenities.hasFencedArea
                            )
                            
                            AmenityToggleRow(
                                icon: "figure.walk",
                                title: "Off-leash OK",
                                isOn: $dogAmenities.allowsOffLeash
                            )
                            
                            AmenityToggleRow(
                                icon: "trash.fill",
                                title: "Waste bags",
                                isOn: $dogAmenities.hasWasteBags
                            )
                            
                            AmenityToggleRow(
                                icon: "shower.fill",
                                title: "Dog wash",
                                isOn: $dogAmenities.hasDogWash
                            )
                        }
                    }
                    
                    // Photos
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photos")
                            .font(.headline)
                        
                        PhotosPicker(
                            selection: $selectedImages,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Add photos")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if !imageData.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<imageData.count, id: \.self) { index in
                                        Image(uiImage: UIImage(data: imageData[index]) ?? UIImage())
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") {
                            submitPlace()
                        }
                        .disabled(name.isEmpty || (address.isEmpty && selectedCoordinate == nil))
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                    showingError = false
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: errorMessage) { oldValue, newValue in
                showingError = newValue != nil
            }
        }
        .onChange(of: selectedImages) { oldValue, newImages in
            loadImages(from: newImages)
        }
        .onChange(of: useMapPicker) { oldValue, isEnabled in
            if isEnabled {
                if let userLocation = locationManager.location {
                    mapRegion = MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    selectedCoordinate = userLocation.coordinate
                } else {
                    // Default: Ann Arbor
                    let defaultCoordinate = CLLocationCoordinate2D(latitude: 42.2464, longitude: -83.7417)
                    mapRegion = MKCoordinateRegion(
                        center: defaultCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    selectedCoordinate = defaultCoordinate
                }
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var newImageData: [Data] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    newImageData.append(data)
                }
            }
            
            await MainActor.run {
                imageData = newImageData
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.isReverseGeocoding = true
            self.selectedCoordinate = coordinate
        }
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                self.isReverseGeocoding = false
                
                if let error = error {
                    print("❌ Reverse geocoding error: \(error.localizedDescription)")
                    self.address = "\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let street = placemark.thoroughfare {
                        addressComponents.append(street)
                    }
                    if let subThoroughfare = placemark.subThoroughfare {
                        addressComponents.append(subThoroughfare)
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        addressComponents.append(administrativeArea)
                    }
                    if let postalCode = placemark.postalCode {
                        addressComponents.append(postalCode)
                    }
                    
                    if addressComponents.isEmpty {
                        self.address = "\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))"
                    } else {
                        self.address = addressComponents.joined(separator: ", ")
                    }
                    
                    print("✅ Reverse geocoding successful: \(self.address)")
                } else {
                    self.address = "\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))"
                }
            }
        }
    }
    
    private func submitPlace() {
        guard !name.isEmpty else { 
            errorMessage = "Please enter a place name"
            return 
        }
        
        guard let userId = authViewModel.currentUser?.id else {
            errorMessage = "Please sign in first"
            return
        }
        
        if useMapPicker {
            guard let coordinate = selectedCoordinate else {
                errorMessage = "Please pick a location on the map"
                return
            }
            
            let finalAddress = address.isEmpty ? "\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))" : address
            
            createAndSavePlace(
                name: name,
                type: selectedType,
                address: finalAddress,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                userId: userId
            )
            return
        }
        
        guard !address.isEmpty else {
            errorMessage = "Please enter an address or pick a location on the map"
            return
        }
        
        isSubmitting = true
        geocodingAddress = true
        errorMessage = nil
        
        print("🔍 Geocoding address: \(address)")
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            DispatchQueue.main.async {
                self.geocodingAddress = false
                
                if let error = error {
                    print("❌ Geocoding error: \(error.localizedDescription)")
                    self.isSubmitting = false
                    self.errorMessage = "Couldn’t find that address: \(error.localizedDescription)"
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let coordinate = placemark.location?.coordinate else {
                    print("❌ No coordinates found for address")
                    self.isSubmitting = false
                    self.errorMessage = "Couldn’t find coordinates for that address. Try a more specific address or use the map picker."
                    return
                }
                
                let latitude = coordinate.latitude
                let longitude = coordinate.longitude
                
                print("✅ Geocoding successful: lat=\(latitude), lng=\(longitude)")
                
                self.createAndSavePlace(
                    name: self.name,
                    type: self.selectedType,
                    address: self.address,
                    latitude: latitude,
                    longitude: longitude,
                    userId: userId
                )
            }
        }
    }
    
    private func createAndSavePlace(name: String, type: Place.PlaceType, address: String, latitude: Double, longitude: Double, userId: String) {
        isSubmitting = true
        errorMessage = nil
        
        let newPlace = Place(
            id: UUID().uuidString,
            name: name,
            type: type,
            address: address,
            latitude: latitude,
            longitude: longitude,
            rating: rating,
            tags: [],
            notes: notes,
            createdBy: userId,
            createdAt: Date(),
            updatedAt: Date(),
            isVerified: false,
            reportCount: 0,
            images: [],
            dogAmenities: dogAmenities
        )
        
        print("🔄 Starting to add place to Firebase: \(newPlace.name)")
        
        // Save to Firebase using PlaceViewModel
        var cancellable: AnyCancellable?
        cancellable = placeViewModel.addPlace(newPlace)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    cancellable?.cancel()
                    self.isSubmitting = false
                    print("📍 Firebase add place completion received")
                    
                    if case .failure(let error) = completion {
                        print("❌ Error adding place to Firebase: \(error.localizedDescription)")
                        self.errorMessage = "Couldn’t save: \(error.localizedDescription)"
                    } else {
                        print("✅ Place added to Firebase successfully")
                        // Success - also update local manager for immediate UI update
                        self.placesManager.addPlace(newPlace)
                        self.dismiss()
                    }
                },
                receiveValue: { _ in
                    print("✅ Place added to Firebase successfully (value received)")
                }
            )
        
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isSubmitting {
                print("⏰ Firebase request timed out")
                cancellable?.cancel()
                self.isSubmitting = false
                self.errorMessage = "Request timed out. Check your network connection."
            }
        }
    }
}

// Map annotation helper (legacy)
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct AmenityToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(isOn ? .green : .gray)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isOn ? .primary : .secondary)
                
                Spacer()
                
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .green : .gray)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddPlaceSheetView()
        .environmentObject(PlaceViewModel())
        .environmentObject(AuthViewModel())
        .environmentObject(LocationManager())
        .environmentObject(PlacesManager())
}
