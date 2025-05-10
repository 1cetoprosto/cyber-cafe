//
//  ImagePicker.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import UIKit
import AVFoundation
import Photos

protocol ImagePickerDelegate: AnyObject {
    func imagePicker(_ picker: ImagePicker, didSelect image: UIImage)
    func imagePickerDidCancel(_ picker: ImagePicker)
}

class ImagePicker: NSObject {
    
    private weak var controller: UIImagePickerController?
    weak var delegate: ImagePickerDelegate? = nil
    
    func showPickerOptions(in presenter: UIViewController, sender: UIView) {
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.addAction(UIAlertAction(title: R.string.global.camera(), style: .default, handler: {[weak self] _ in
            self?.showCamera(in: presenter)
        }))
        
        sheetController.addAction(UIAlertAction(title: R.string.global.gallery(), style: .default, handler: {[weak self] _ in
            self?.showGallery(in: presenter)
        }))
        
        sheetController.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel, handler: nil))
        
        sheetController.popoverPresentationController?.sourceView = sender
        sheetController.popoverPresentationController?.sourceRect = sender.bounds
        sheetController.popoverPresentationController?.permittedArrowDirections = [.any]
        
        presenter.present(sheetController, animated: true)
    }
    
    func showCamera(in presenter: UIViewController) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            present(in: presenter, source: .camera)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if granted {
                        self.present(in: presenter, source: .camera)
                    } else {
                        self.showAlert(targetName: R.string.global.camera()) { success in
                            guard success else { return }
                            self.present(in: presenter, source: .camera)
                        }
                    }
                }
            }
        }
    }
    
    func showGallery(in presenter: UIViewController) {
        PHPhotoLibrary.requestAuthorization { [weak self] result in
            guard let self = self else { return }
            let isAllowed: Bool
            if #available(iOS 14, *) {
                isAllowed = result == .authorized || result == .limited
            } else {
                isAllowed = result == .authorized
            }
            DispatchQueue.main.async {
                if isAllowed {
                    self.present(in: presenter, source: .photoLibrary)
                } else {
                    self.showAlert(targetName: R.string.global.gallery()) { success in
                        guard success else { return }
                        self.present(in: presenter, source: .photoLibrary)
                    }
                }
            }
        }
    }
    
    private func present(in presenter: UIViewController, source: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = source
        controller.allowsEditing = true
        self.controller = controller
        DispatchQueue.main.async {
            presenter.present(controller, animated: true, completion: nil)
        }
    }
    
    func dismiss() {
        controller?.dismiss(animated: true, completion: nil)
    }
}

extension ImagePicker {
    
        // FIXME: - add localization
    private func showAlert(targetName: String, completion: @escaping (Bool)->()) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alertVC = UIAlertController(title: R.string.global.access_image_title(targetName),
                                            message: R.string.global.access_image_desc(targetName),
                                            preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: R.string.global.menuSettings(),
                                            style: .default,
                                            handler: { action in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(settingsUrl) else { completion(false); return }
                UIApplication.shared.open(settingsUrl, options: [:]) { [weak self] _ in
                    self?.showAlert(targetName: targetName, completion: completion)
                }
            }))
            alertVC.addAction(UIAlertAction(title: R.string.global.cancel(),
                                            style: .cancel,
                                            handler: { _ in completion(false) }))
            UIApplication.shared.delegate?.window??.rootViewController?.present(alertVC, animated: true, completion: nil)
        }
    }
    
    
}

extension ImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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

