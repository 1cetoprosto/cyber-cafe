import FirebaseStorage
import Foundation

protocol ImageStorageServiceProtocol {
    func upload(data: Data, toPath path: String, contentType: String) async throws
    func delete(atPath path: String) async throws
    func downloadData(atPath path: String, maxSize: Int64) async throws -> Data
}

final class FirebaseImageStorageService: ImageStorageServiceProtocol {
    static let shared = FirebaseImageStorageService()

    private func makeReference(path: String) -> StorageReference {
        var ref = Storage.storage().reference()
        for part in path.split(separator: "/").map(String.init) where !part.isEmpty {
            ref = ref.child(part)
        }
        return ref
    }

    func upload(data: Data, toPath path: String, contentType: String) async throws {
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

    private func putData(ref: StorageReference, data: Data, metadata: StorageMetadata) async throws
    {
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
