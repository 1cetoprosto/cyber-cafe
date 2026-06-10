import CryptoKit
import Foundation

actor ImageDataCache {
    static let shared = ImageDataCache()

    private let memoryCache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let directoryURL: URL?

    init() {
        self.memoryCache.countLimit = 256
        self.memoryCache.totalCostLimit = 64 * 1024 * 1024

        guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            self.directoryURL = nil
            return
        }
        self.directoryURL = caches.appendingPathComponent("ImageDataCache", isDirectory: true)
    }

    func data(forKey key: String) -> Data? {
        if let cached = memoryCache.object(forKey: key as NSString) {
            return Data(referencing: cached)
        }
        guard let fileURL = diskURL(forKey: key) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        return data
    }

    func store(_ data: Data, forKey key: String) {
        memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        guard let dir = directoryURL else { return }

        if !fileManager.fileExists(atPath: dir.path) {
            _ = try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        guard let fileURL = diskURL(forKey: key) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    func remove(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        guard let fileURL = diskURL(forKey: key) else { return }
        try? fileManager.removeItem(at: fileURL)
    }

    private func diskURL(forKey key: String) -> URL? {
        guard let dir = directoryURL else { return nil }
        let digest = SHA256.hash(data: Data(key.utf8))
        let fileName = digest.map { String(format: "%02x", $0) }.joined()
        return dir.appendingPathComponent(fileName).appendingPathExtension("bin")
    }
}

