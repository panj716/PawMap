import Foundation
import FirebaseStorage
import FirebaseAuth
import Combine
import UIKit

/// Service for handling file uploads and downloads with Firebase Storage
class StorageService: ObservableObject {
    static let shared = StorageService()
    
    private let storage = Storage.storage()
    private let imageCache = ImageCache.shared
    
    private init() {}
    
    // MARK: - Image Upload
    
    /// Upload an image to Firebase Storage
    func uploadImage(_ image: UIImage, to path: String, compressionQuality: CGFloat = 0.8) -> AnyPublisher<String, Error> {
        return Future { [weak self] promise in
            guard let self = self,
                  let imageData = image.jpegData(compressionQuality: compressionQuality) else {
                promise(.failure(StorageError.invalidImage))
                return
            }
            
            let storageRef = self.storage.reference().child(path)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        promise(.failure(StorageError.downloadURLFailed))
                        return
                    }
                    
                    // Cache the image locally
                    self.imageCache.store(image, for: downloadURL.absoluteString)
                    
                    promise(.success(downloadURL.absoluteString))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Upload multiple images
    func uploadImages(_ images: [UIImage], to basePath: String, compressionQuality: CGFloat = 0.8) -> AnyPublisher<[String], Error> {
        let uploadPublishers = images.enumerated().map { index, image in
            let path = "\(basePath)/\(UUID().uuidString)_\(index).jpg"
            return uploadImage(image, to: path, compressionQuality: compressionQuality)
        }
        
        return Publishers.MergeMany(uploadPublishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Image Download
    
    /// Download an image from Firebase Storage
    func downloadImage(from url: String) -> AnyPublisher<UIImage?, Error> {
        // Check cache first
        if let cachedImage = imageCache.image(for: url) {
            return Just(cachedImage)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Future { [weak self] promise in
            guard let self = self,
                  let storageURL = URL(string: url) else {
                promise(.failure(StorageError.invalidURL))
                return
            }
            
            let storageRef = self.storage.reference(forURL: url)
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let data = data,
                      let image = UIImage(data: data) else {
                    promise(.failure(StorageError.invalidImageData))
                    return
                }
                
                // Cache the image
                self.imageCache.store(image, for: url)
                promise(.success(image))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - File Management
    
    /// Delete an image from Firebase Storage
    func deleteImage(at url: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(StorageError.serviceUnavailable))
                return
            }
            
            let storageRef = self.storage.reference(forURL: url)
            storageRef.delete { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                // Remove from cache
                self.imageCache.removeImage(for: url)
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Delete multiple images
    func deleteImages(at urls: [String]) -> AnyPublisher<Void, Error> {
        let deletePublishers = urls.map { url in
            deleteImage(at: url)
        }
        
        return Publishers.MergeMany(deletePublishers)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Path Generation
    
    /// Generate a unique path for user profile images
    func generateProfileImagePath(for userId: String) -> String {
        return "users/\(userId)/profile/\(UUID().uuidString).jpg"
    }
    
    /// Generate a unique path for place images
    func generatePlaceImagePath(for placeId: String) -> String {
        return "places/\(placeId)/images/\(UUID().uuidString).jpg"
    }
    
    /// Generate a unique path for review images
    func generateReviewImagePath(for reviewId: String) -> String {
        return "reviews/\(reviewId)/images/\(UUID().uuidString).jpg"
    }
    
    // MARK: - Image Processing
    
    /// Resize image to specified dimensions
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    /// Compress image to reduce file size
    func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    // MARK: - Batch Operations
    
    /// Upload images in batches to avoid overwhelming the service
    func uploadImagesInBatches(_ images: [UIImage], to basePath: String, batchSize: Int = 3) -> AnyPublisher<[String], Error> {
        let batches = images.chunked(into: batchSize)
        let batchPublishers = batches.map { batch in
            uploadImages(batch, to: basePath)
        }
        
        return Publishers.Sequence(sequence: batchPublishers)
            .flatMap { $0 }
            .collect()
            .map { results in
                results.flatMap { $0 }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

enum StorageError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidImageData
    case downloadURLFailed
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid storage URL"
        case .invalidImageData:
            return "Invalid image data received"
        case .downloadURLFailed:
            return "Failed to get download URL"
        case .serviceUnavailable:
            return "Storage service is unavailable"
        }
    }
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
