//
//  UIColor.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 20.11.2021.
//

import UIKit

extension UIColor {
    
    struct Main {
//        static var messageQuestion: UIColor { HEX.hA8A8A8 }
        static var text: UIColor { HEX.h1C3209 }
//        static var style: UIColor { HEX.h1B1B1B }
//        static var accent1: UIColor { HEX.h7C35D7 }
        static var background: UIColor { HEX.hC49E62 }
        //static var inactiveIcons: UIColor { HEX.hCCAEF3 }
    }
    
    struct Button {
        static var title: UIColor { HEX.h1C3209 }
        static var background: UIColor { HEX.h1C3209 }
//        static var active: UIColor { HEX.hC4C4C4 }
//        static var passive: UIColor { HEX.hDEDEDE }
//        static var cover: UIColor { HEX.hB1B1B1 }
//        static var passiveDesign: UIColor { HEX.hDFC9FC }
    }
    
    struct TabBar {
//        static var tint: UIColor { HEX.h7C35D7 }
//        static var unselectedTint: UIColor { HEX.hCCAEF3 }
    }
    
    struct TableView {
        static var cellBackground: UIColor { HEX.hEFD4A0 }
        static var cellLabel: UIColor { HEX.h5E4420 }
    }
    
    fileprivate struct HEX {
        //main colors
        static let h1C3209 = UIColor(hex: 0x1C3209)
        static let h131205 = UIColor(hex: 0x131205)
        static let h985C17 = UIColor(hex: 0x985C17)
        static let hFBFBF9 = UIColor(hex: 0xFBFBF9)
        static let hEFD4A0 = UIColor(hex: 0xEFD4A0)
        static let h5E4420 = UIColor(hex: 0x5E4420)
        static let hC49E62 = UIColor(hex: 0xC49E62)
        static let hA85524 = UIColor(hex: 0xA85524)
    }
    
}

extension UIColor {
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
}

