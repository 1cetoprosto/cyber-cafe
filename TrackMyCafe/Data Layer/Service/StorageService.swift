//
//  StorageService.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 01.07.2024.
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    
    static func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            completion(nil)
            return
        }
        let ref = Storage.storage().reference()
            .child(Refs.comments.rawValue)
            .child(Refs.photos.rawValue)
            .child(UUID().uuidString + ".jpeg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(data, metadata: metadata) { (_, error) in
            if error != nil {
                completion(nil)
            }
            ref.downloadURL { (url, _) in
                completion(url?.absoluteString)
            }
        }
    }
    
    static func uploadAudio(_ filePath: String, completion: @escaping (String?) -> Void) {
        let ref = Storage.storage().reference()
            .child(Refs.comments.rawValue)
            .child(Refs.audio.rawValue)
            .child(UUID().uuidString + ".m4a")
        
        ref.putFile(from: URL(fileURLWithPath: filePath), metadata: nil) { (_, error) in
            if error != nil {
                completion(nil)
            }
            ref.downloadURL { (url, _) in
                completion(url?.absoluteString)
            }
        }
    }
    
    static func uploadAvatar(_ image: UIImage, name: String, completion: @escaping (Bool, String?, String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let ref = Storage.storage().reference().child(Refs.avatars.rawValue).child(name + ".jpeg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(data, metadata: metadata) { (metadata, error) in
            guard error == nil else {
                completion(false, nil, nil)
                return
            }
            ref.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    ref.delete(completion: nil)
                    completion(false, nil, nil)
                    return
                }
                
                let scaledImage = image.resizeImage(100, opaque: false)
                guard let dataThumbnail = scaledImage.jpegData(compressionQuality: 0.9) else {
                    ref.delete(completion: nil)
                    completion(false, nil, nil)
                    return
                }
                
                let thumbnailRef = Storage.storage().reference().child(Refs.avatars.rawValue).child(name + "_thumbnail.jpeg")
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                thumbnailRef.putData(dataThumbnail, metadata: metadata) { (metadata, error) in
                    guard error == nil else {
                        ref.delete(completion: nil)
                        completion(false, nil, nil)
                        return
                    }
                    thumbnailRef.downloadURL { (url, error) in
                        guard let thumbnailDownloadURL = url else {
                            ref.delete(completion: nil)
                            thumbnailRef.delete(completion: nil)
                            completion(false, nil, nil)
                            return
                        }
                        
                        completion(true, downloadURL.absoluteString, thumbnailDownloadURL.absoluteString)
                    }
                }
            }
        }
    }
}

