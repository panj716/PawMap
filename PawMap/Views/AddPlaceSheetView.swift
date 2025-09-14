import SwiftUI
import PhotosUI
import CoreLocation

struct AddPlaceSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var userManager: UserManager
    
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
                    Button("提交") {
                        submitPlace()
                    }
                    .disabled(name.isEmpty || address.isEmpty || isSubmitting)
                }
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
        guard !name.isEmpty, !address.isEmpty else { return }
        
        isSubmitting = true
        
        // 创建新地点
        let newPlace = Place(
            id: UUID().uuidString,
            name: name,
            type: selectedType,
            address: address,
            latitude: locationManager.location?.coordinate.latitude ?? 0.0,
            longitude: locationManager.location?.coordinate.longitude ?? 0.0,
            rating: rating,
            tags: [],
            notes: notes,
            userName: userManager.currentUser?.name ?? "匿名用户",
            isAutoLoaded: false,
            verificationCount: 0,
            source: "用户添加",
            reviews: [],
            dogAmenities: dogAmenities,
            images: imageData.map { $0.base64EncodedString() },
            createdAt: Date(),
            updatedAt: Date(),
            reports: [],
            isVerified: false
        )
        
        placesManager.addPlace(newPlace)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            dismiss()
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
