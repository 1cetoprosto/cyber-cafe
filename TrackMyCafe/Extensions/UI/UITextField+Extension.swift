//
//  UITextField.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 05.12.2021.
//

import UIKit

extension UITextField {
    convenience init(placeholder: String, font: UIFont?, aligment: NSTextAlignment = .left) {
        self.init()
        self.textAlignment = aligment
        self.placeholder = placeholder
        self.font = font
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
