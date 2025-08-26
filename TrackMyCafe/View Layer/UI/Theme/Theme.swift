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
            return ThemeStyle(rawValue: styleIdValue) ?? .light
        }
        set {
            _current = nil
            UserDefaults.standard.setValue(newValue.rawValue, forKey: kThemeStyle)
            UserDefaults.standard.synchronize()
            
            // Застосовуємо системну тему
            applySystemTheme(newValue)
        }
    }
    
    private static var _current: ThemeProtocol!
    static var current: ThemeProtocol {
        if let theme = _current { return theme }
        _current = AssetTheme()
        return _current
    }
    
    // Застосування системної теми
    private static func applySystemTheme(_ themeStyle: ThemeStyle) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                switch themeStyle {
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                }
            }
        }
    }
}

enum ThemeStyle: Int, CaseIterable {
    case light = 0
    case dark = 1
    
    var themeName: String {
        switch self {
        case .light: return "Світла"
        case .dark: return "Темна"
        }
    }
}

struct AssetTheme: ThemeProtocol {
    
    private func color(_ name: String, fallback: UIColor) -> UIColor {
        guard let color = UIColor(named: name) else {
            #if DEBUG
            print("⚠️ Warning: Color '\(name)' not found in Assets.xcassets, using fallback")
            #endif
            return fallback
        }
        return color
    }
    
    var primaryText: UIColor {
        color("PrimaryText", fallback: .label)
    }
    
    var primaryBackground: UIColor {
        color("PrimaryBackground", fallback: .systemBackground)
    }
    
    var secondaryText: UIColor {
        color("SecondaryText", fallback: .secondaryLabel)
    }
    
    var secondaryBackground: UIColor {
        color("SecondaryBackground", fallback: .secondarySystemBackground)
    }
    
    var tabBarTint: UIColor {
        color("TabBarTint", fallback: .systemBlue)
    }
    
    var cellBackground: UIColor {
        color("CellBackground", fallback: .systemBackground)
    }
    
    var navBarBackground: UIColor {
        color("NavBarBackground", fallback: .systemBackground)
    }
    
    var navBarText: UIColor {
        color("NavBarText", fallback: .label)
    }
}
