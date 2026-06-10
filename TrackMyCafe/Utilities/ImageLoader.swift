import Foundation
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

    func loadImage(forPathOrURL pathOrURL: String) async throws -> UIImage {
        if let cached = await cache.data(forKey: pathOrURL), let image = UIImage(data: cached) {
            return image
        }

        let data: Data
        if let url = URL(string: pathOrURL), url.scheme == "http" || url.scheme == "https" {
            let (downloaded, _) = try await urlSession.data(from: url)
            data = downloaded
        } else {
            data = try await storageService.downloadData(atPath: pathOrURL, maxSize: 15 * 1024 * 1024)
        }

        await cache.store(data, forKey: pathOrURL)
        guard let image = UIImage(data: data) else {
            await cache.remove(forKey: pathOrURL)
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}

