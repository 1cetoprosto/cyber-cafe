//
//  UIColor.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 20.11.2021.
//

import UIKit

extension UIColor {

    struct Main {
        static var text: UIColor { Theme.current.primaryText }
        static var background: UIColor { Theme.current.primaryBackground }
        static var accent: UIColor { Theme.current.secondaryText }
    }

    struct Button {
        static var title: UIColor { Theme.current.primaryBackground }
        static var background: UIColor { Theme.current.secondaryBackground }
    }

    struct TabBar {
        static var tint: UIColor { Theme.current.tabBarTint }
    }

    struct TableView {
        static var cellBackground: UIColor { Theme.current.cellBackground }
        static var cellLabel: UIColor { Theme.current.primaryText }
    }

    struct NavBar {
        static var background: UIColor { Theme.current.navBarBackground }
        static var text: UIColor { Theme.current.navBarText }
    }

//    fileprivate struct HEX {
//        // main colors
//        static let h1C3209 = UIColor(hex: 0x1C3209)
//        static let h131205 = UIColor(hex: 0x131205)
//        static let h985C17 = UIColor(hex: 0x985C17)
//        static let hFBFBF9 = UIColor(hex: 0xFBFBF9)
//        static let hEFD4A0 = UIColor(hex: 0xEFD4A0)
//        static let h5E4420 = UIColor(hex: 0x5E4420)
//        static let hC49E62 = UIColor(hex: 0xC49E62)
//        static let hA85524 = UIColor(hex: 0xA85524)
//    }

    // TODO: має залишитись лише ця частина, те що вище потрібно обєднати із цією частиною
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red)/255,
                  green: CGFloat(green)/255,
                  blue: CGFloat(blue)/255,
                  alpha: 1.0)
    }
    
    static func random() -> UIColor {
        return UIColor(
            red:   .random(),
            green: .random(),
            blue:  .random(),
            alpha: 1.0
        )
    }
    
    func alpha(_ value: CGFloat) -> UIColor {
        return self.withAlphaComponent(value)
    }
    
    var rgba32: RGBA32? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        return RGBA32(red: UInt8(red*255.0), green: UInt8(green*255.0), blue: UInt8(blue*255.0), alpha: UInt8(alpha*255.0))
    }
}

struct RGBA32: Equatable {
    private var color: UInt32
    
    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let red   = UInt32(red)
        let green = UInt32(green)
        let blue  = UInt32(blue)
        let alpha = UInt32(alpha)
        color = (red << 24) | (green << 16) | (blue << 8) | (alpha << 0)
    }
    
    static let red     = RGBA32(red: 255, green: 0,   blue: 0,   alpha: 255)
    static let green   = RGBA32(red: 0,   green: 255, blue: 0,   alpha: 255)
    static let blue    = RGBA32(red: 0,   green: 0,   blue: 255, alpha: 255)
    static let white   = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
    static let black   = RGBA32(red: 0,   green: 0,   blue: 0,   alpha: 255)
    static let magenta = RGBA32(red: 255, green: 0,   blue: 255, alpha: 255)
    static let yellow  = RGBA32(red: 255, green: 255, blue: 0,   alpha: 255)
    static let cyan    = RGBA32(red: 0,   green: 255, blue: 255, alpha: 255)
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    
    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.color == rhs.color
    }
}

//extension UIColor {
//    convenience init(hex: Int) {
//        let components = (
//            R: CGFloat((hex >> 16) & 0xff) / 255,
//            G: CGFloat((hex >> 08) & 0xff) / 255,
//            B: CGFloat((hex >> 00) & 0xff) / 255
//        )
//        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
//    }
//}

