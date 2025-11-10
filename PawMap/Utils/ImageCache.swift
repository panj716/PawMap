import Foundation
import UIKit
import Combine

/// Service for caching images locally to improve performance
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configure memory cache
        cache.countLimit = 100 // Maximum 100 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Setup disk cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Clean up old cache files on startup
        cleanupOldCacheFiles()
    }
    
    // MARK: - Public Methods
    
    /// Store an image in cache
    func store(_ image: UIImage, for key: String) {
        let nsKey = NSString(string: key)
        
        // Store in memory cache
        cache.setObject(image, forKey: nsKey)
        
        // Store in disk cache
        storeImageToDisk(image, for: key)
    }
    
    /// Retrieve an image from cache
    func image(for key: String) -> UIImage? {
        let nsKey = NSString(string: key)
        
        // Try memory cache first
        if let cachedImage = cache.object(forKey: nsKey) {
            return cachedImage
        }
        
        // Try disk cache
        if let diskImage = loadImageFromDisk(for: key) {
            // Store back in memory cache
            cache.setObject(diskImage, forKey: nsKey)
            return diskImage
        }
        
        return nil
    }
    
    /// Remove an image from cache
    func removeImage(for key: String) {
        let nsKey = NSString(string: key)
        
        // Remove from memory cache
        cache.removeObject(forKey: nsKey)
        
        // Remove from disk cache
        removeImageFromDisk(for: key)
    }
    
    /// Clear all cached images
    func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    // MARK: - Private Methods
    
    private func storeImageToDisk(_ image: UIImage, for key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
    }
    
    private func loadImageFromDisk(for key: String) -> UIImage? {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        return UIImage(data: data)
    }
    
    private func removeImageFromDisk(for key: String) {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func sanitizeFileName(_ fileName: String) -> String {
        // Remove invalid characters and create a hash for the filename
        let sanitized = fileName.replacingOccurrences(of: "[^a-zA-Z0-9._-]", with: "_", options: .regularExpression)
        return sanitized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "unknown"
    }
    
    private func cleanupOldCacheFiles() {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        
        for case let fileURL as URL in enumerator {
            if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
               creationDate < oneWeekAgo {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - AsyncImageCache

/// Async image cache for SwiftUI integration
class AsyncImageCache: ObservableObject {
    static let shared = AsyncImageCache()
    
    private let imageCache = ImageCache.shared
    private let storageService = StorageService.shared
    
    private init() {}
    
    /// Load image asynchronously with caching
    func loadImage(from url: String) -> AnyPublisher<UIImage?, Never> {
        // Check cache first
        if let cachedImage = imageCache.image(for: url) {
            return Just(cachedImage)
                .eraseToAnyPublisher()
        }
        
        // Download from Firebase Storage
        return storageService.downloadImage(from: url)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    /// Preload images for better performance
    func preloadImages(_ urls: [String]) {
        for url in urls {
            _ = loadImage(from: url)
                .sink { _ in }
        }
    }
}

// MARK: - Image Processing Extensions

extension UIImage {
    /// Resize image to specified size
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    /// Compress image to reduce file size
    func compressed(quality: CGFloat = 0.8) -> Data? {
        return jpegData(compressionQuality: quality)
    }
    
    /// Create thumbnail
    func thumbnail(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        return resized(to: size)
    }
}
