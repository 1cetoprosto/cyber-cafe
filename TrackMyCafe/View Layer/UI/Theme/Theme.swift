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

  //static var currentThemeStyle: ThemeStyle = .light

  private static let kThemeStyle = UserDefaultsKeys.themeStyle
  private static let kFirstLaunch = UserDefaultsKeys.firstLaunch

  static var currentThemeStyle: ThemeStyle {
    get {
      // Check if this is the first launch
      if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.firstLaunch) {
        // Set system theme as default on first launch
        UserDefaults.standard.setValue(
          ThemeStyle.system.rawValue, forKey: UserDefaultsKeys.themeStyle)
        UserDefaults.standard.setValue(true, forKey: UserDefaultsKeys.firstLaunch)
        UserDefaults.standard.synchronize()
        return .system
      }

      let styleIdValue =
        (UserDefaults.standard.value(forKey: UserDefaultsKeys.themeStyle) as? Int) ?? 2
      return ThemeStyle(rawValue: styleIdValue) ?? .system
    }
    set {
      _current = nil
      UserDefaults.standard.setValue(newValue.rawValue, forKey: UserDefaultsKeys.themeStyle)
      UserDefaults.standard.synchronize()

      // Apply system theme
      applySystemTheme(newValue)
    }
  }

  private static var _current: ThemeProtocol!
  static var current: ThemeProtocol {
    if let theme = _current { return theme }
    switch currentThemeStyle {
    case .lightAlt:
      _current = SoftLightTheme()
    default:
      _current = AssetTheme()
    }
    return _current
  }

  // Застосування системної теми
  private static func applySystemTheme(_ themeStyle: ThemeStyle) {
    DispatchQueue.main.async {
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first
      {

        switch themeStyle {
        case .light:
          window.overrideUserInterfaceStyle = .light
        case .lightAlt:
          window.overrideUserInterfaceStyle = .light
        case .dark:
          window.overrideUserInterfaceStyle = .dark
        case .system:
          window.overrideUserInterfaceStyle = .unspecified
        }
      }
    }
  }

  // Detect current system theme
  private static func detectSystemTheme() -> ThemeStyle {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    {
      return window.traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }
    // Fallback to system trait collection if window is not available
    return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
  }

  // Method for automatic system theme following
  static func followSystemTheme() {
    if currentThemeStyle == .system {
      let detectedTheme = detectSystemTheme()
      applySystemTheme(detectedTheme)
    }
  }

  // Apply current theme on app launch
  static func applyCurrentTheme() {
    let currentTheme = currentThemeStyle
    if currentTheme == .system {
      let detectedTheme = detectSystemTheme()
      applySystemTheme(detectedTheme)
    } else {
      applySystemTheme(currentTheme)
    }
  }
}

enum ThemeStyle: Int, CaseIterable {
  case light = 0
  case dark = 1
  case system = 2
  case lightAlt = 3

  var themeName: String {
    switch self {
    case .light: return R.string.global.lightThemeName()
    case .dark: return R.string.global.darkThemeName()
    case .system: return R.string.global.systemThemeName()
    case .lightAlt: return R.string.global.lightAltThemeName()
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

// Alternative light theme palette backed by Assets.xcassets (Colors/*Alt)
struct SoftLightTheme: ThemeProtocol {

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
    color("PrimaryTextAlt", fallback: UIColor(red: 34, green: 34, blue: 34))
  }

  var primaryBackground: UIColor {
    // Soft off-white background
    color("PrimaryBackgroundAlt", fallback: UIColor(red: 250, green: 250, blue: 250))
  }

  var secondaryText: UIColor {
    // Muted secondary text
    color("SecondaryTextAlt", fallback: UIColor(red: 90, green: 98, blue: 110))
  }

  var secondaryBackground: UIColor {
    // Very light gray-blue for grouped backgrounds
    color("SecondaryBackgroundAlt", fallback: UIColor(red: 240, green: 243, blue: 247))
  }

  var tabBarTint: UIColor {
    // iOS-style blue tint
    color("TabBarTintAlt", fallback: UIColor(red: 0, green: 122, blue: 255))
  }

  var cellBackground: UIColor {
    color("CellBackgroundAlt", fallback: .white)
  }

  var navBarBackground: UIColor {
    // Slightly tinted light background to distinguish nav bar
    color("NavBarBackgroundAlt", fallback: UIColor(red: 252, green: 252, blue: 255))
  }

  var navBarText: UIColor {
    color("NavBarTextAlt", fallback: UIColor(red: 34, green: 34, blue: 34))
  }
}
