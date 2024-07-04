//
//  UIImageView+Extension.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit
import Kingfisher

extension UIImageView {
    
    func setImage(_ URL: URL?, placeholder: UIImage?) {
        guard let imageURL = URL else {
            self.image = placeholder
            return
        }
        setImage(imageURL, placeholder: placeholder)
    }
}
