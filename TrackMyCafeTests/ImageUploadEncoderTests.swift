import UIKit
import XCTest

@testable import TrackMyCafe_Dev

final class ImageUploadEncoderTests: XCTestCase {

    func testJPEGEncoderKeepsLargePhotoUnderStorageLimit() {
        let image = makeSolidImage(width: 4000, height: 3000, color: .systemPink)
        let data = ImageUploadEncoder.jpegDataForUpload(from: image)

        XCTAssertNotNil(data)
        XCTAssertLessThanOrEqual(
            data?.count ?? Int.max,
            ImageUploadEncoder.maxUploadBytes
        )
    }

    func testJPEGEncoderHandlesSquarePhoto() {
        let image = makeSolidImage(width: 3024, height: 3024, color: .systemTeal)
        let data = ImageUploadEncoder.jpegDataForUpload(from: image)

        XCTAssertNotNil(data)
        XCTAssertLessThanOrEqual(
            data?.count ?? Int.max,
            ImageUploadEncoder.maxUploadBytes
        )
    }

    // MARK: - Helpers

    private func makeSolidImage(width: CGFloat, height: CGFloat, color: UIColor) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
