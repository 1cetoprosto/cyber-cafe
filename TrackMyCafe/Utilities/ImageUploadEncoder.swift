import UIKit

/// Client-side resize + JPEG encode for Firebase Storage uploads.
/// `storage.rules` rejects writes ≥ 2 MB (`isWithinUploadLimit`).
enum ImageUploadEncoder {
    /// Must stay strictly below the Storage rule limit (< 2 MB).
    static let maxUploadBytes = (2 * 1024 * 1024) - 1

    private static let defaultMaxPixelDimension: CGFloat = 1400
    private static let minimumPixelDimension: CGFloat = 480
    private static let initialQuality: CGFloat = 0.86
    private static let minimumQuality: CGFloat = 0.4
    private static let qualityStep: CGFloat = 0.12

    /// Returns JPEG data that fits Storage rules, or `nil` if encoding fails.
    static func jpegDataForUpload(
        from image: UIImage,
        maxPixelDimension: CGFloat = defaultMaxPixelDimension,
        maxBytes: Int = maxUploadBytes
    ) -> Data? {
        var dimension = maxPixelDimension
        while dimension >= minimumPixelDimension {
            guard let rendered = render(image, maxPixelDimension: dimension) else {
                return nil
            }
            if let data = encodeUnderLimit(rendered, maxBytes: maxBytes) {
                return data
            }
            dimension = floor(dimension * 0.75)
        }
        return nil
    }

    // MARK: - Private

    private static func render(_ image: UIImage, maxPixelDimension: CGFloat) -> UIImage? {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > 0 else { return nil }

        let scale = min(1, maxPixelDimension / longestSide)
        let targetSize = CGSize(
            width: max(1, floor(size.width * scale)),
            height: max(1, floor(size.height * scale))
        )

        // Critical: default renderer uses the screen scale (2x/3x), which can turn
        // "1400 pt" into 4200 px and push JPEG over the 2 MB Storage rule.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private static func encodeUnderLimit(_ image: UIImage, maxBytes: Int) -> Data? {
        var quality = initialQuality
        while quality >= minimumQuality - 0.001 {
            if let data = image.jpegData(compressionQuality: quality),
               data.count <= maxBytes
            {
                return data
            }
            quality -= qualityStep
        }
        return nil
    }
}
