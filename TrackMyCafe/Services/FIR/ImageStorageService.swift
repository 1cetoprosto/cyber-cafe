import FirebaseStorage
import Foundation
import UIKit

// MARK: - AvatarUploadResult

struct AvatarUploadResult {
    let fullURL: String
    let thumbnailURL: String
}

// MARK: - ImageStorageServiceProtocol

protocol ImageStorageServiceProtocol {
    func upload(data: Data, toPath path: String, contentType: String) async throws
    func delete(atPath path: String) async throws
    func downloadData(atPath path: String, maxSize: Int64) async throws -> Data
    func downloadURL(atPath path: String) async throws -> URL
    func uploadAvatar(image: UIImage, fileName: String) async throws -> AvatarUploadResult
}

// MARK: - FirebaseImageStorageService

final class FirebaseImageStorageService: ImageStorageServiceProtocol {
    static let shared = FirebaseImageStorageService()

    private init() {}

    private func makeReference(path: String) -> StorageReference {
        var ref = Storage.storage().reference()
        for part in path.split(separator: "/").map(String.init) where !part.isEmpty {
            ref = ref.child(part)
        }
        return ref
    }

    func upload(data: Data, toPath path: String, contentType: String) async throws {
        guard data.count <= ImageUploadEncoder.maxUploadBytes else {
            throw NSError(
                domain: "ImageStorageUpload",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Image exceeds Storage limit (\(data.count) bytes > \(ImageUploadEncoder.maxUploadBytes))"
                ]
            )
        }

        let metadata = StorageMetadata()
        metadata.contentType = contentType

        try await putData(ref: makeReference(path: path), data: data, metadata: metadata)
    }

    func delete(atPath path: String) async throws {
        let ref = makeReference(path: path)
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let error, self.isObjectNotFound(error) {
                    continuation.resume(returning: ())
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    func downloadData(atPath path: String, maxSize: Int64) async throws -> Data {
        return try await getData(ref: makeReference(path: path), maxSize: maxSize)
    }

    func downloadURL(atPath path: String) async throws -> URL {
        let ref = makeReference(path: path)
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let url {
                    continuation.resume(returning: url)
                    return
                }
                continuation.resume(throwing: error ?? URLError(.badServerResponse))
            }
        }
    }

    func uploadAvatar(image: UIImage, fileName: String) async throws -> AvatarUploadResult {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw URLError(.cannotDecodeContentData)
        }

        let avatarObjectPath = ImageStoragePaths.avatarPath(
            fileName: fileName + "." + FileExtensions.jpeg
        )

        try await upload(data: data, toPath: avatarObjectPath, contentType: "image/jpeg")

        let fullURL: URL
        do {
            fullURL = try await downloadURL(atPath: avatarObjectPath)
        } catch {
            try? await delete(atPath: avatarObjectPath)
            throw error
        }

        let scaledImage = image.resizeImage(100, opaque: false)
        guard let dataThumbnail = scaledImage.jpegData(compressionQuality: 0.9) else {
            try? await delete(atPath: avatarObjectPath)
            throw URLError(.cannotDecodeContentData)
        }

        let thumbnailObjectPath = ImageStoragePaths.avatarPath(
            fileName: fileName + FileExtensions.thumbnailJpeg
        )

        do {
            try await upload(data: dataThumbnail, toPath: thumbnailObjectPath, contentType: "image/jpeg")
        } catch {
            try? await delete(atPath: avatarObjectPath)
            throw error
        }

        let thumbnailURL: URL
        do {
            thumbnailURL = try await downloadURL(atPath: thumbnailObjectPath)
        } catch {
            try? await delete(atPath: avatarObjectPath)
            try? await delete(atPath: thumbnailObjectPath)
            throw error
        }

        return AvatarUploadResult(
            fullURL: fullURL.absoluteString,
            thumbnailURL: thumbnailURL.absoluteString
        )
    }

    /// Completion bridge for legacy call sites (Staff / Admin avatar upload).
    func uploadAvatar(
        _ image: UIImage,
        name fileName: String,
        completion: @escaping (_ success: Bool, _ fullURL: String?, _ thumbnailURL: String?) -> Void
    ) {
        Task {
            do {
                let result = try await uploadAvatar(image: image, fileName: fileName)
                await MainActor.run {
                    completion(true, result.fullURL, result.thumbnailURL)
                }
            } catch {
                await MainActor.run {
                    completion(false, nil, nil)
                }
            }
        }
    }

    private func putData(ref: StorageReference, data: Data, metadata: StorageMetadata) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func getData(ref: StorageReference, maxSize: Int64) async throws -> Data {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Data, Error>) in
            ref.getData(maxSize: maxSize) { data, error in
                if let data {
                    continuation.resume(returning: data)
                    return
                }
                continuation.resume(throwing: error ?? URLError(.badServerResponse))
            }
        }
    }

    private func isObjectNotFound(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == StorageErrorDomain else { return false }
        return StorageErrorCode(rawValue: nsError.code) == .objectNotFound
    }
}