//
//  UIDevice+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import UIKit

extension UIDevice {
    
    static var hasTopNotch: Bool {
        if #available(iOS 11.0,  *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        return false
    }
    
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension UIScreen {
    var minEdge: CGFloat {
        return UIScreen.main.bounds.minEdge
    }
}
