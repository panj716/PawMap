import SwiftUI
import PhotosUI

struct AddUserContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var contentManager: UserContentManager
    
    let place: Place
    
    @State private var comment = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var loadedImages: [Data] = []
    @State private var showingImagePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Share Your Experience") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell others about your visit to \(place.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Write a comment...", text: $comment, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                Section("Add Photos") {
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Add Photos")
                            Spacer()
                            Text("\(selectedImages.count)/5")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !loadedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, imageData in
                                    if let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                Button(action: {
                                                    loadedImages.remove(at: index)
                                                    if index < selectedImages.count {
                                                        selectedImages.remove(at: index)
                                                    }
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 30, y: -30),
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !comment.isEmpty || !loadedImages.isEmpty {
                    Section("Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            if !comment.isEmpty {
                                Text(comment)
                                    .font(.body)
                            }
                            
                            if !loadedImages.isEmpty {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                    ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, imageData in
                                        if let uiImage = UIImage(data: imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Post") {
                            postContent()
                        }
                        .disabled(comment.isEmpty && loadedImages.isEmpty)
                    }
                }
            }
        }
        .onChange(of: selectedImages) { _, newImages in
            Task {
                loadedImages.removeAll()
                for item in newImages {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loadedImages.append(data)
                    }
                }
            }
        }
    }
    
    private func postContent() {
        guard let user = userManager.currentUser else { return }
        
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            contentManager.addContent(
                placeId: place.id,
                userId: user.id,
                userName: user.name,
                comment: comment,
                images: loadedImages
            )
            
            isLoading = false
            dismiss()
        }
    }
}
