import SwiftUI
import PhotosUI
import CoreLocation
import Combine

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
    @State private var geocodingAddress = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("添加新地点")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("分享您发现的狗狗友好场所")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 基本信息
                    VStack(alignment: .leading, spacing: 16) {
                        Text("基本信息")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            TextField("地点名称", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("类型", selection: $selectedType) {
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
                            
                            TextField("地址", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("描述和备注", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    
                    // 评分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("您的评分")
                            .font(.headline)
                        
                        HStack {
                            Text("评分: \(String(format: "%.1f", rating))")
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
                    
                    // 狗狗设施
                    VStack(alignment: .leading, spacing: 16) {
                        Text("狗狗设施")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            AmenityToggleRow(
                                icon: "bowl.fill",
                                title: "狗碗",
                                isOn: $dogAmenities.hasDogBowl
                            )
                            
                            AmenityToggleRow(
                                icon: "house.fill",
                                title: "室内允许",
                                isOn: $dogAmenities.hasIndoorAccess
                            )
                            
                            AmenityToggleRow(
                                icon: "leaf.fill",
                                title: "仅户外",
                                isOn: $dogAmenities.isOutdoorOnly
                            )
                            
                            AmenityToggleRow(
                                icon: "gift.fill",
                                title: "狗零食",
                                isOn: $dogAmenities.hasDogTreats
                            )
                            
                            AmenityToggleRow(
                                icon: "drop.fill",
                                title: "饮水站",
                                isOn: $dogAmenities.hasWaterStation
                            )
                            
                            AmenityToggleRow(
                                icon: "sun.max.fill",
                                title: "遮阳",
                                isOn: $dogAmenities.hasShade
                            )
                            
                            AmenityToggleRow(
                                icon: "fence",
                                title: "围栏区域",
                                isOn: $dogAmenities.hasFencedArea
                            )
                            
                            AmenityToggleRow(
                                icon: "figure.walk",
                                title: "可松绳",
                                isOn: $dogAmenities.allowsOffLeash
                            )
                            
                            AmenityToggleRow(
                                icon: "trash.fill",
                                title: "垃圾袋",
                                isOn: $dogAmenities.hasWasteBags
                            )
                            
                            AmenityToggleRow(
                                icon: "shower.fill",
                                title: "狗狗洗澡",
                                isOn: $dogAmenities.hasDogWash
                            )
                        }
                    }
                    
                    // 照片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("照片")
                            .font(.headline)
                        
                        PhotosPicker(
                            selection: $selectedImages,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("添加照片")
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
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("提交") {
                            submitPlace()
                        }
                        .disabled(name.isEmpty || address.isEmpty)
                    }
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onChange(of: selectedImages) { newImages in
            loadImages(from: newImages)
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
    
    private func submitPlace() {
        guard !name.isEmpty, !address.isEmpty else { 
            errorMessage = "请填写地点名称和地址"
            return 
        }
        
        guard let userId = authViewModel.currentUser?.id else {
            errorMessage = "请先登录"
            return
        }
        
        isSubmitting = true
        geocodingAddress = true
        errorMessage = nil
        
        print("🔍 Geocoding address: \(address)")
        
        // Geocode the address to get latitude and longitude
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [self] placemarks, error in
            geocodingAddress = false
            
            if let error = error {
                print("❌ Geocoding error: \(error.localizedDescription)")
                isSubmitting = false
                errorMessage = "无法找到该地址: \(error.localizedDescription)"
                return
            }
            
            guard let placemark = placemarks?.first,
                  let coordinate = placemark.location?.coordinate else {
                print("❌ No coordinates found for address")
                isSubmitting = false
                errorMessage = "无法找到该地址的坐标，请尝试输入更详细的地址"
                return
            }
            
            let latitude = coordinate.latitude
            let longitude = coordinate.longitude
            
            print("✅ Geocoding successful: lat=\(latitude), lng=\(longitude)")
            
            // 创建新地点
            let newPlace = Place(
                id: UUID().uuidString,
                name: name,
                type: selectedType,
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
                        isSubmitting = false
                        print("📍 Firebase add place completion received")
                        
                        if case .failure(let error) = completion {
                            print("❌ Error adding place to Firebase: \(error.localizedDescription)")
                            self.errorMessage = "保存失败: \(error.localizedDescription)"
                        } else {
                            print("✅ Place added to Firebase successfully")
                            // Success - also update local manager for immediate UI update
                            placesManager.addPlace(newPlace)
                            dismiss()
                        }
                    },
                    receiveValue: { _ in
                        print("✅ Place added to Firebase successfully (value received)")
                    }
                )
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if isSubmitting {
                    print("⏰ Firebase request timed out")
                    cancellable?.cancel()
                    isSubmitting = false
                    self.errorMessage = "请求超时，请检查网络连接"
                }
            }
        }
    }
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
        .environmentObject(PlacesManager())
        .environmentObject(LocationManager())
        .environmentObject(UserManager())
}
