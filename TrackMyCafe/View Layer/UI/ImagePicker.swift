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
    weak var delegate: ImagePickerDelegate? = nil

    func showPickerOptions(in presenter: UIViewController, sender: UIView) {
        // Functionality disabled as per requirements
        /*
        let sheetController = UIAlertController(
            title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.addAction(
            UIAlertAction(
                title: R.string.global.camera(), style: .default,
                handler: { [weak self] _ in
                    self?.showCamera(in: presenter)
                }))

        sheetController.addAction(
            UIAlertAction(
                title: R.string.global.gallery(), style: .default,
                handler: { [weak self] _ in
                    self?.showGallery(in: presenter)
                }))

        sheetController.addAction(
            UIAlertAction(title: R.string.global.cancel(), style: .cancel, handler: nil))

        sheetController.popoverPresentationController?.sourceView = sender
        sheetController.popoverPresentationController?.sourceRect = sender.bounds
        sheetController.popoverPresentationController?.permittedArrowDirections = [.any]

        presenter.present(sheetController, animated: true)
        */
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
            let alertVC = UIAlertController(
                title: R.string.global.access_image_title(),
                message: R.string.global.access_image_desc(targetName),
                preferredStyle: .alert)
            alertVC.addAction(
                UIAlertAction(
                    title: R.string.global.menuSettings(),
                    style: .default,
                    handler: { action in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                            UIApplication.shared.canOpenURL(settingsUrl)
                        else {
                            completion(false)
                            return
                        }
                        UIApplication.shared.open(settingsUrl, options: [:]) { [weak self] _ in
                            self?.showAlert(targetName: targetName, completion: completion)
                        }
                    }))
            alertVC.addAction(
                UIAlertAction(
                    title: R.string.global.cancel(),
                    style: .cancel,
                    handler: { _ in completion(false) }))
            UIViewController.topMostViewController()?.present(alertVC, animated: true, completion: nil)
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
