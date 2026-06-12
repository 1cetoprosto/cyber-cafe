import FirebaseCore
import FirebaseStorage
import Foundation

protocol ImageStorageServiceProtocol {
    func upload(data: Data, toPath path: String, contentType: String) async throws
    func delete(atPath path: String) async throws
    func downloadData(atPath path: String, maxSize: Int64) async throws -> Data
}

final class FirebaseImageStorageService: ImageStorageServiceProtocol {
    static let shared = FirebaseImageStorageService()

    enum UploadValidationError: LocalizedError {
        case payloadTooLarge(maxBytes: Int, actualBytes: Int)

        var errorDescription: String? {
            switch self {
            case .payloadTooLarge(let maxBytes, let actualBytes):
                return
                    "Image is too large to upload (\(actualBytes) bytes). Max allowed is \(maxBytes) bytes."
            }
        }
    }

    private enum ErrorDomain {
        static let storageUpload = "FirebaseImageStorageService.upload"
    }

    private enum UploadPolicy {
        static let maxUploadBytes = 2 * 1024 * 1024
    }

    private func makeReference(path: String) -> StorageReference {
        var ref = Storage.storage().reference()
        for part in path.split(separator: "/").map(String.init) where !part.isEmpty {
            ref = ref.child(part)
        }
        return ref
    }

    private func environmentDescription() -> String {
        let options = FirebaseApp.app()?.options
        let projectId = options?.projectID ?? "unknown"
        let bucket = options?.storageBucket ?? "unknown"
        return "projectId=\(projectId), bucket=\(bucket)"
    }

    private func wrapUploadError(_ error: Error, path: String) -> Error {
        let nsError = error as NSError
        guard nsError.domain == StorageErrorDomain else { return error }

        let code = StorageErrorCode(rawValue: nsError.code)
        let env = environmentDescription()

        switch code {
        case .objectNotFound, .bucketNotFound:
            return NSError(
                domain: ErrorDomain.storageUpload,
                code: nsError.code,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase Storage is not available for this environment or is misconfigured (\(env)). Please enable Storage for this Firebase project or verify GoogleService-Info.plist. Path: \(path)."
                ]
            )
        case .unauthenticated, .unauthorized:
            return NSError(
                domain: ErrorDomain.storageUpload,
                code: nsError.code,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase Storage permission error (\(env)). Please verify Firebase Auth state and Storage rules. Path: \(path)."
                ]
            )
        default:
            return NSError(
                domain: ErrorDomain.storageUpload,
                code: nsError.code,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Firebase Storage upload failed (\(env)). Path: \(path). Error: \(error.localizedDescription)"
                ]
            )
        }
    }

    func upload(data: Data, toPath path: String, contentType: String) async throws {
        guard data.count <= UploadPolicy.maxUploadBytes else {
            throw UploadValidationError.payloadTooLarge(
                maxBytes: UploadPolicy.maxUploadBytes,
                actualBytes: data.count
            )
        }

        let metadata = StorageMetadata()
        metadata.contentType = contentType

        do {
            try await putData(ref: makeReference(path: path), data: data, metadata: metadata)
        } catch {
            throw wrapUploadError(error, path: path)
        }
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
