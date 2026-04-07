//
//  ImageCache.swift
//  WorkoutBuilderApp
//

import UIKit

// In-memory image cache using NSCache to avoid redundant network downloads.
// Images are keyed by their URL string and automatically evicted under memory pressure.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared

    private static let allowedHosts: Set<String> = [
        "raw.githubusercontent.com"
    ]

    private init() {
        cache.countLimit = 200
    }

    // Returns a cached image for the given URL, or fetches it from the network.
    // Returns nil if the URL fails validation or the download fails.
    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard ImageCache.isValid(url: url) else {
            return nil
        }

        guard let (data, _) = try? await session.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }

        cache.object(forKey: key)
        cache.setObject(image, forKey: key)
        return image
    }

    // Validates that a URL uses HTTPS and points to an allowed host.
    static func isValid(url: URL) -> Bool {
        guard url.scheme == "https" else { return false }
        guard let host = url.host(), allowedHosts.contains(host) else { return false }
        return true
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    // Loads multiple images concurrently, returning them in order.
    // Used by views that need to display a set of images (e.g., exercise animations).
    func images(for urls: [URL]) async -> [UIImage] {
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask { (index, await self.image(for: url)) }
            }
            var results = [(Int, UIImage)]()
            for await (index, img) in group {
                if let img { results.append((index, img)) }
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
}



