//
//  ImagePicker.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import UIKit

protocol ImagePickerDelegate: AnyObject {
    func imagePicker(_ picker: ImagePicker, didSelect image: UIImage)
    func imagePickerDidCancel(_ picker: ImagePicker)
}

class ImagePicker: NSObject {

    private weak var controller: UIImagePickerController?
    weak var delegate: ImagePickerDelegate?

    func showPickerOptions(in presenter: UIViewController, sender: UIView) {
        // Functionality disabled as per requirements
    }

    func showCamera(in presenter: UIViewController) {
        // Functionality disabled
    }

    func showGallery(in presenter: UIViewController) {
        // Functionality disabled
    }

    private func present(in presenter: UIViewController, source: UIImagePickerController.SourceType)
    {
        // Functionality disabled
    }

    func dismiss() {
        controller?.dismiss(animated: true, completion: nil)
    }
}

extension ImagePicker {

    // FIXME: - add localization
    private func showAlert(targetName: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            PopupFactory.showPopup(
                title: R.string.global.access_image_title(),
                description: R.string.global.access_image_desc(targetName),
                buttonTitle: R.string.global.menuSettings(),
                buttonAction: {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                        UIApplication.shared.canOpenURL(settingsUrl)
                    else {
                        completion(false)
                        return
                    }
                    UIApplication.shared.open(settingsUrl, options: [:]) { [weak self] _ in
                        self?.showAlert(targetName: targetName, completion: completion)
                    }
                },
                onCancel: {
                    completion(false)
                }
            )
        }
    }

}

extension ImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let image = info[.editedImage] as? UIImage {
            delegate?.imagePicker(self, didSelect: image)
            return
        }

        if let image = info[.originalImage] as? UIImage {
            delegate?.imagePicker(self, didSelect: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.imagePickerDidCancel(self)
    }
}
