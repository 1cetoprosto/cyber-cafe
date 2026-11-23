import ImageIO
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache: ImageDataCache
    private let storageService: ImageStorageServiceProtocol
    private let urlSession: URLSession

    init(
        cache: ImageDataCache = .shared,
        storageService: ImageStorageServiceProtocol = FirebaseImageStorageService.shared,
        urlSession: URLSession = .shared
    ) {
        self.cache = cache
        self.storageService = storageService
        self.urlSession = urlSession
    }

    /// Loads image data (cached or remote), then optionally creates a downscaled decode
    /// via ImageIO to avoid main-thread jank with full-resolution JPEGs.
    func loadImage(forPathOrURL pathOrURL: String, maxPixelSize: Int? = nil) async throws -> UIImage {
        let data: Data
        if let cached = await cache.data(forKey: pathOrURL) {
            data = cached
        } else if let url = URL(string: pathOrURL),
                  url.scheme == "http" || url.scheme == "https"
        {
            let (downloaded, _) = try await urlSession.data(from: url)
            data = downloaded
            await cache.store(data, forKey: pathOrURL)
        } else {
            data = try await storageService.downloadData(
                atPath: pathOrURL,
                maxSize: 15 * 1024 * 1024
            )
            await cache.store(data, forKey: pathOrURL)
        }

        if let maxPixelSize, maxPixelSize > 0 {
            return try makeDownscaledImage(from: data, maxPixelSize: maxPixelSize)
        }

        guard let image = UIImage(data: data) else {
            await cache.remove(forKey: pathOrURL)
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }

    // MARK: - Private

    private func makeDownscaledImage(from data: Data, maxPixelSize: Int) throws -> UIImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
              )
        else {
            throw URLError(.cannotDecodeContentData)
        }
        return UIImage(cgImage: cgImage)
    }
}
