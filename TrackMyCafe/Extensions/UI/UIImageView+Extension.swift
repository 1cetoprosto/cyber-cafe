//
//  UIImageView+Extension.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import ObjectiveC
import UIKit

private final class ImageLoadTaskBox: NSObject {
    var task: Task<Void, Never>?
}

private enum UIImageViewAssociatedKeys {
    static var imageLoadTaskBox = "UIImageView.imageLoadTaskBox"
    static var imageLoadToken = "UIImageView.imageLoadToken"
}

enum AppImagePlaceholder {
    static func product() -> UIImage? {
        make(
            systemName: "photo",
            pointSize: 28
        )
    }

    static func category() -> UIImage? {
        make(
            systemName: "photo",
            pointSize: 24
        )
    }

    static func photo() -> UIImage? {
        make(
            systemName: "photo",
            pointSize: 28
        )
    }

    private static func make(systemName: String, pointSize: CGFloat) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        return UIImage(systemName: systemName, withConfiguration: configuration)?
            .withTintColor(
                UIColor.TabBar.tint.withAlphaComponent(0.62),
                renderingMode: .alwaysOriginal
            )
    }
}

extension UIImageView {
    func cancelImageLoad() {
        (objc_getAssociatedObject(self, &UIImageViewAssociatedKeys.imageLoadTaskBox)
            as? ImageLoadTaskBox)?
            .task?
            .cancel()
        objc_setAssociatedObject(
            self,
            &UIImageViewAssociatedKeys.imageLoadTaskBox,
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    func setImage(pathOrURL: String?, placeholder: UIImage?) {
        cancelImageLoad()

        guard let pathOrURL, !pathOrURL.isEmpty else {
            image = placeholder
            return
        }

        image = placeholder

        let token = UUID().uuidString
        objc_setAssociatedObject(
            self,
            &UIImageViewAssociatedKeys.imageLoadToken,
            token,
            .OBJC_ASSOCIATION_COPY_NONATOMIC
        )

        let box = ImageLoadTaskBox()
        box.task = Task { [weak self] in
            do {
                let img = try await ImageLoader.shared.loadImage(forPathOrURL: pathOrURL)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self else { return }
                    let currentToken =
                        objc_getAssociatedObject(self, &UIImageViewAssociatedKeys.imageLoadToken)
                        as? String
                    guard currentToken == token else { return }
                    self.image = img
                }
            } catch {
                guard !Task.isCancelled else { return }
            }
        }
        objc_setAssociatedObject(
            self,
            &UIImageViewAssociatedKeys.imageLoadTaskBox,
            box,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    func setImage(_ url: URL?, placeholder: UIImage?) {
        guard let url else {
            setImage(pathOrURL: nil, placeholder: placeholder)
            return
        }
        setImage(url, placeholder: placeholder)
    }

    func setImage(_ url: URL, placeholder: UIImage?) {
        setImage(pathOrURL: url.absoluteString, placeholder: placeholder)
    }
}
