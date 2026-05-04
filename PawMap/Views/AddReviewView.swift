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
                Section(header: Text("Rating")) {
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
                
                Section(header: Text("Review")) {
                    TextField("Share your experience…", text: $comment, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section(header: Text("Photos")) {
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.pink)
                            Text("Add photos")
                                .foregroundColor(.primary)
                            Spacer()
                            if !imageData.isEmpty {
                                Text("\(imageData.count) photos")
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
                    Button("Submit review") {
                        submitReview()
                    }
                    .disabled(comment.isEmpty)
                    .foregroundColor(.pink)
                }
            }
            .navigationTitle("Add review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
            .alert("Review submitted", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thanks! Your review was submitted.")
            }
        }
    }
    
    private func submitReview() {
        let _ = Review(
            id: UUID().uuidString,
            placeId: place.id,
            userId: userManager.currentUser?.id ?? "anonymous",
            userName: userManager.currentUser?.name ?? "Anonymous",
            rating: rating,
            comment: comment,
            images: imageData.map { $0.base64EncodedString() },
            createdAt: Date(),
            helpfulCount: 0,
            helpfulVoters: []
        )
        
        // placesManager.addReview(to: place.id, review: newReview) // TODO: Implement addReview method
        showingSuccessAlert = true
    }
}

#Preview {
    AddReviewView(place: Place(
        name: "Sample place",
        type: .coffee,
        address: "Sample address",
        latitude: 42.9634,
        longitude: -85.6681,
        notes: "Sample notes",
        createdBy: "test-user-id"
    ))
    .environmentObject(PlacesManager())
    .environmentObject(UserManager())
}
