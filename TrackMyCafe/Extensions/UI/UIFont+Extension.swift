//
//  UIFont.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.11.2021.
//

import UIKit

enum AvenirNextWeight {
    case regular
    case light
    case medium
    case demiBold
    case bold
    
    var name: String {
        switch self {
        case .regular: return "AvenirNext-Regular"
        case .light: return "AvenirNext-UltraLight"
        case .medium: return "AvenirNext-Medium"
        case .demiBold: return "AvenirNext-DemiBold"
        case .bold: return "AvenirNext-Bold"
        }
    }
    
    var system: UIFont.Weight {
        switch self {
        case .regular: return .regular
        case .light: return .light
        case .medium: return .medium
        case .demiBold: return .semibold
        case .bold: return .bold
        }
    }
}

enum AvenirNext {
    static func font(size: CGFloat, weight: AvenirNextWeight = .regular) -> UIFont {
        UIFont(name: weight.name, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight.system)
    }
}

enum FontPalette {
    static func system(_ style: UIFont.TextStyle) -> UIFont {
        UIFont.preferredFont(forTextStyle: style)
    }
    
    static func avenir(_ style: UIFont.TextStyle, weight: AvenirNextWeight = .regular) -> UIFont {
        let baseSize = UIFont.preferredFont(forTextStyle: style).pointSize
        let base = AvenirNext.font(size: baseSize, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }
}

enum Typography {
    static let footnote = FontPalette.avenir(.footnote, weight: .regular)
    static let footnoteLight = FontPalette.avenir(.footnote, weight: .light)
    static let body = FontPalette.avenir(.body, weight: .regular)
    static let bodyMedium = FontPalette.avenir(.body, weight: .medium)
    static let bodyBold = FontPalette.avenir(.body, weight: .bold)
    static let title3 = FontPalette.avenir(.title3, weight: .regular)
    static let title3DemiBold = FontPalette.avenir(.title3, weight: .demiBold)
    static let largeTitle = FontPalette.avenir(.largeTitle, weight: .regular)
    static let headline = FontPalette.avenir(.headline, weight: .regular)
    static let headlineMedium = FontPalette.avenir(.headline, weight: .medium)
}

extension UILabel {
    func applyDynamic(_ font: UIFont) {
        self.font = font
        self.adjustsFontForContentSizeCategory = true
    }
}

extension UIFont {
    
    static func avenirNext20() -> UIFont? {
        return UIFont.init(name: "Avenir Next", size: 20)
    }
    
    static func avenirNext14() -> UIFont? {
        return UIFont.init(name: "Avenir Next", size: 14)
    }
    
    static func avenirNextDemiBold20() -> UIFont? {
        return UIFont.init(name: "Avenir Next Demi Bold", size: 20)
    }
    
    static func avenirNextDemiBold14() -> UIFont? {
        return UIFont.init(name: "Avenir Next Demi Bold", size: 14)
    }
    
}
