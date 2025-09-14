import SwiftUI
import PhotosUI

struct AddReviewView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var placesManager: PlacesManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("评分")) {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                        }
                        Spacer()
                        Text("\(rating)/5")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("评论")) {
                    TextField("分享你的体验...", text: $comment, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section(header: Text("照片")) {
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.pink)
                            Text("添加照片")
                                .foregroundColor(.primary)
                            Spacer()
                            if !imageData.isEmpty {
                                Text("\(imageData.count) 张照片")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if !imageData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<imageData.count, id: \.self) { index in
                                    if let uiImage = UIImage(data: imageData[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                Button(action: {
                                                    imageData.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 5, y: -5),
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Section {
                    Button("提交评论") {
                        submitReview()
                    }
                    .disabled(comment.isEmpty)
                    .foregroundColor(.pink)
                }
            }
            .navigationTitle("添加评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImages) { newImages in
                Task {
                    imageData.removeAll()
                    for image in newImages {
                        if let data = try? await image.loadTransferable(type: Data.self) {
                            imageData.append(data)
                        }
                    }
                }
            }
            .alert("评论已提交", isPresented: $showingSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("感谢您的反馈！您的评论已成功提交。")
            }
        }
    }
    
    private func submitReview() {
        let newReview = Review(
            user: userManager.currentUser?.name ?? "匿名用户",
            rating: rating,
            comment: comment,
            date: Date(),
            userPhotos: imageData.map { $0.base64EncodedString() },
            isHelpful: 0,
            helpfulVoters: []
        )
        
        placesManager.addReview(to: place.id, review: newReview)
        showingSuccessAlert = true
    }
}

#Preview {
    AddReviewView(place: Place(
        id: "preview",
        name: "测试地点",
        type: .coffee,
        address: "测试地址",
        latitude: 42.9634,
        longitude: -85.6681,
        rating: 4.5,
        tags: [],
        notes: "测试笔记",
        userName: "测试用户",
        isAutoLoaded: false,
        verificationCount: 0,
        source: "测试",
        reviews: [],
        dogAmenities: DogAmenities.empty,
        images: [],
        createdAt: Date(),
        updatedAt: Date(),
        reports: [],
        isVerified: true
    ))
    .environmentObject(PlacesManager())
    .environmentObject(UserManager())
}
