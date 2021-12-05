//
//  UILabel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 05.12.2021.
//

import UIKit

extension UILabel {
    
    convenience init(text: String, font: UIFont?, aligment: NSTextAlignment = .left) {
        self.init()
        
        self.text = text
        self.font = font
        self.textColor = .black
        self.textAlignment = aligment
        self.adjustsFontSizeToFitWidth = true
        self.translatesAutoresizingMaskIntoConstraints = false
        //self.backgroundColor = .systemRed
    }
}
