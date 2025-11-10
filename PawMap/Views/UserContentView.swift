import SwiftUI

struct UserContentView: View {
    let place: Place
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var contentManager: UserContentManager
    @State private var showingAddContent = false
    
    private var userContent: [UserPlaceContent] {
        contentManager.getContentForPlace(place.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Rate & Review")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if userManager.isLoggedIn {
                    Button("Add") {
                        showingAddContent = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Content
            if userContent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "message")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No reviews yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to share your experience!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(userContent.sorted(by: { $0.createdAt > $1.createdAt })) { content in
                        UserContentCard(content: content, placeId: place.id)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContent) {
            AddUserContentView(place: place)
                .environmentObject(userManager)
                .environmentObject(contentManager)
        }
    }
}

struct UserContentCard: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var contentManager: UserContentManager
    
    let content: UserPlaceContent
    let placeId: String
    
    private var isLiked: Bool {
        guard let user = userManager.currentUser else { return false }
        return contentManager.isContentLiked(UUID(uuidString: content.id) ?? UUID(), userId: user.id, placeId: placeId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(content.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    guard let user = userManager.currentUser else { return }
                    contentManager.likeContent(UUID(uuidString: content.id) ?? UUID(), userId: user.id, placeId: placeId)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        
                        Text("\(content.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!userManager.isLoggedIn)
            }
            
            // Comment
            if !content.comment.isEmpty {
                Text(content.comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Images
            if !content.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(content.imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            // For now, show a placeholder since we're using URLs
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    UserContentView(place: Place(
        name: "Preview Place",
        type: .coffee,
        address: "123 Main St",
        latitude: 42.2464,
        longitude: -83.7417,
        rating: 4.5,
        tags: ["dogFriendly"],
        notes: "Preview place",
        createdBy: "system"
    ))
    .environmentObject(UserManager())
    .environmentObject(UserContentManager())
}