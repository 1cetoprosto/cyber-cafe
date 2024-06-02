//
//  Theme.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import UIKit

protocol ThemeProtocol {
    var primaryText: UIColor { get }
    var primaryBackground: UIColor { get }
    var secondaryText: UIColor { get }
    var secondaryBackground: UIColor { get }
    var tabBarTint: UIColor { get }
    var cellBackground: UIColor { get }
    var navBarBackground: UIColor { get }
    var navBarText: UIColor { get }
}

class Theme {
    
    private static let kThemeStyle = "kThemeStyle"
    static var currentThemeStyle: ThemeStyle {
        get {
            let styleIdValue = (UserDefaults.standard.value(forKey: kThemeStyle) as? Int) ?? 0
            return ThemeStyle(rawValue: styleIdValue) ?? .brown
        }
        set {
            _current = nil
            UserDefaults.standard.setValue(newValue.rawValue, forKey: kThemeStyle)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static var _current: ThemeProtocol!
    static var current: ThemeProtocol {
        if let theme = _current { return theme }
        _current = currentThemeStyle.theme
        return _current
    }
    
}

enum ThemeStyle: Int, CaseIterable {
    case brown = 0
    case blue = 1
    
    var theme: ThemeProtocol {
        switch self {
            case .brown: return BrownTheme()
            case .blue: return BlueTheme()
        }
    }
    
    var themeName: String {
        switch self {
            case .brown: return "Default"
            case .blue: return "Bluegray"
        }
    }
}

struct BrownTheme: ThemeProtocol {
    var primaryText: UIColor { return UIColor(hex: "#1C3209") }         //темно-зелений
    var primaryBackground: UIColor { return UIColor(hex: "#C49E62") }   //кава з молоком
    var secondaryText: UIColor { return UIColor(hex: "#EFD4A0") }       //світлий кава з молоком
    var secondaryBackground: UIColor { return UIColor(hex: "#1C3209") } //темно-зелений
    var tabBarTint: UIColor { return UIColor(hex: "#1C3209") }          //темно-зелений
    var cellBackground: UIColor { return UIColor(hex: "#EFD4A0") }      //світлий кава з молоком
    var navBarBackground: UIColor { return UIColor(hex: "#1C3209") }    //темно-зелений
    var navBarText: UIColor { return UIColor(hex: "#EFD4A0") }          //світлий кава з молоком
}

struct BlueTheme: ThemeProtocol {
    var primaryText: UIColor { return UIColor(hex: "#FFFFFF") }
    var primaryBackground: UIColor { return UIColor(hex: "#0000FF") }
    var secondaryText: UIColor { return UIColor(hex: "#FFFFFF") }
    var secondaryBackground: UIColor { return UIColor(hex: "#0000FF") }
    var tabBarTint: UIColor { return UIColor(hex: "#0000FF") }
    var cellBackground: UIColor { return UIColor(hex: "#EFD4A0") }
    var navBarBackground: UIColor { return UIColor(hex: "#0000FF") }
    var navBarText: UIColor { return UIColor(hex: "#FFFFFF") }
}
