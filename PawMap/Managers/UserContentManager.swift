import Foundation
import SwiftUI
import PhotosUI

class UserContentManager: ObservableObject {
    @Published var userPlaceContent: [String: [UserPlaceContent]] = [:] // placeId -> [UserPlaceContent]
    
    private let userDefaults = UserDefaults.standard
    private let contentKey = "userPlaceContent"
    
    init() {
        loadUserContent()
    }
    
    func addContent(placeId: String, userId: String, userName: String, comment: String, images: [Data]) {
        let newContent = UserPlaceContent(
            placeId: placeId,
            userId: userId,
            userName: userName,
            comment: comment,
            imageURLs: [] // Will be populated after uploading images
        )
        
        if userPlaceContent[placeId] == nil {
            userPlaceContent[placeId] = []
        }
        userPlaceContent[placeId]?.append(newContent)
        saveUserContent()
    }
    
    func getContentForPlace(_ placeId: String) -> [UserPlaceContent] {
        return userPlaceContent[placeId] ?? []
    }
    
    func likeContent(_ contentId: UUID, userId: String, placeId: String) {
        guard let content = userPlaceContent[placeId]?.first(where: { $0.id == contentId.uuidString }) else { return }
        
        var updatedLikedBy = content.likedBy
        let newLikes: Int
        
        if updatedLikedBy.contains(userId) {
            // Unlike
            updatedLikedBy.removeAll { $0 == userId }
            newLikes = max(0, content.likes - 1)
        } else {
            // Like
            updatedLikedBy.append(userId)
            newLikes = content.likes + 1
        }
        
        let updatedContent = UserPlaceContent(
            id: content.id,
            placeId: content.placeId,
            userId: content.userId,
            userName: content.userName,
            comment: content.comment,
            imageURLs: content.imageURLs,
            likes: newLikes,
            likedBy: updatedLikedBy,
            createdAt: content.createdAt,
            updatedAt: Date()
        )
        
        if let index = userPlaceContent[placeId]?.firstIndex(where: { $0.id == contentId.uuidString }) {
            userPlaceContent[placeId]?[index] = updatedContent
            saveUserContent()
        }
    }
    
    func isContentLiked(_ contentId: UUID, userId: String, placeId: String) -> Bool {
        guard let content = userPlaceContent[placeId]?.first(where: { $0.id == contentId.uuidString }) else { return false }
        return content.likedBy.contains(userId)
    }
    
    private func saveUserContent() {
        if let data = try? JSONEncoder().encode(userPlaceContent) {
            userDefaults.set(data, forKey: contentKey)
        }
    }
    
    private func loadUserContent() {
        guard let data = userDefaults.data(forKey: contentKey),
              let content = try? JSONDecoder().decode([String: [UserPlaceContent]].self, from: data) else {
            return
        }
        userPlaceContent = content
    }
}
