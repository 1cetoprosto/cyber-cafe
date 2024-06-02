//
//  SVProgressHUD+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import SVProgressHUD

extension SVProgressHUD {
    
    static func showSuccess() {
        SVProgressHUD.showSuccess(withStatus: nil)
    }
    
    static func show(_ show: Bool) {
        if show {
            SVProgressHUD.show()
        } else {
            SVProgressHUD.dismiss()
        }
    }
}
