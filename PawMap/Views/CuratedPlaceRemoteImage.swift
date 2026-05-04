import SwiftUI
import UIKit

/// Loads curated hero images with a proper User-Agent (Wikimedia policy) and tries `fallbackImageURL` if the primary fails.
private enum CuratedPlaceImageLoader {
    static let userAgent = "PawMap/1.0 (iOS; PawMap app; +https://apps.apple.com)"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": userAgent]
        config.timeoutIntervalForRequest = 28
        return URLSession(configuration: config)
    }()

    static func loadFirstImage(urlStrings: [String]) async -> UIImage? {
        for raw in urlStrings {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let url = URL(string: trimmed) else { continue }
            var request = URLRequest(url: url)
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { continue }
                let mime = (http.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
                if mime.contains("text/html") {
                    continue
                }
                if let image = UIImage(data: data) { return image }
            } catch {
                continue
            }
        }
        return nil
    }
}

struct CuratedPlaceRemoteImage: View {
    let place: CuratedPlace
    var contentMode: ContentMode = .fill

    @State private var loaded: UIImage?

    private var urlChain: [String] {
        var urls: [String] = [place.imageURL]
        if let f = place.fallbackImageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !f.isEmpty,
           f != place.imageURL {
            urls.append(f)
        }
        return urls
    }

    private var loadIdentity: String {
        "\(place.id)|\(place.imageURL)|\(place.fallbackImageURL ?? "")"
    }

    var body: some View {
        ZStack {
            if let loaded {
                Image(uiImage: loaded)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                LinearGradient(
                    colors: [Color.pink.opacity(0.22), Color.purple.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: place.type.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.95))
            }
        }
        .task(id: loadIdentity) {
            await MainActor.run { loaded = nil }
            let image = await CuratedPlaceImageLoader.loadFirstImage(urlStrings: urlChain)
            await MainActor.run { loaded = image }
        }
    }
}
