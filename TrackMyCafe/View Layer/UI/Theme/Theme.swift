//
//  Theme.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import OSLog
import UIKit

protocol ThemeProtocol {
  var primaryText: UIColor { get }
  var primaryBackground: UIColor { get }
  var secondaryText: UIColor { get }
  var secondaryBackground: UIColor { get }
  var tabBarTint: UIColor { get }
  var tabBarUnselectedTint: UIColor { get }
  var cellBackground: UIColor { get }
  var navBarBackground: UIColor { get }
  var navBarText: UIColor { get }
}

// MARK: - Two-dimensional theme selection
enum AppearanceStyle: Int {
  case system = 0
  case light = 1
  case dark = 2
}

enum PaletteStyle: Int {
  case standard = 0
  case alt = 1
  case coffeeWithMilk = 2
}

struct ThemeSelection {
  let appearance: AppearanceStyle
  let palette: PaletteStyle
}

// Top-level theme options for the picker (Latte first)
enum ThemeOption: CaseIterable {
  // Latte (CoffeeWithMilk) first in the picker
  case coffeeAuto
  case coffeeLight
  case coffeeDark
  // Then Classic (Standard)
  case automatic
  case light
  case dark
  // Then Slate (Alt)
  case altAuto
  case lightAlt
  case darkAlt

  static var allCases: [ThemeOption] {
    return [
      .coffeeAuto,
      .coffeeLight,
      .coffeeDark,
    ]
  }

  var displayName: String {
    switch self {
    case .automatic: return R.string.global.systemThemeName()
    case .light: return R.string.global.lightThemeName()
    case .dark: return R.string.global.darkThemeName()
    case .altAuto: return R.string.global.systemAltThemeName()
    case .lightAlt: return R.string.global.lightAltThemeName()
    case .darkAlt: return R.string.global.darkAltThemeName()
    case .coffeeAuto: return R.string.global.coffeeWithMilkThemeName()
    case .coffeeLight: return R.string.global.coffeeWithMilkLightThemeName()
    case .coffeeDark: return R.string.global.coffeeWithMilkDarkThemeName()
    }
  }

  var selection: ThemeSelection {
    switch self {
    case .automatic: return ThemeSelection(appearance: .system, palette: .standard)
    case .light: return ThemeSelection(appearance: .light, palette: .standard)
    case .dark: return ThemeSelection(appearance: .dark, palette: .standard)
    case .altAuto: return ThemeSelection(appearance: .system, palette: .alt)
    case .lightAlt: return ThemeSelection(appearance: .light, palette: .alt)
    case .darkAlt: return ThemeSelection(appearance: .dark, palette: .alt)
    case .coffeeAuto: return ThemeSelection(appearance: .system, palette: .coffeeWithMilk)
    case .coffeeLight: return ThemeSelection(appearance: .light, palette: .coffeeWithMilk)
    case .coffeeDark: return ThemeSelection(appearance: .dark, palette: .coffeeWithMilk)
    }
  }
}

class Theme {

  //static var currentThemeStyle: ThemeStyle = .light

  private static let kThemeStyle = UserDefaultsKeys.themeStyle
  private static let kFirstLaunch = UserDefaultsKeys.firstLaunch
  private static let kAppearanceStyle = UserDefaultsKeys.appearanceStyle
  private static let kPaletteStyle = UserDefaultsKeys.paletteStyle

  // MARK: - New selection storage
  static var currentSelection: ThemeSelection {
    get {
      // First run: default to Coffee with Milk following system
      if !UserDefaults.standard.bool(forKey: kFirstLaunch) {
        let defaultSelection = ThemeSelection(appearance: .system, palette: .coffeeWithMilk)
        UserDefaults.standard.set(true, forKey: kFirstLaunch)
        UserDefaults.standard.set(defaultSelection.appearance.rawValue, forKey: kAppearanceStyle)
        UserDefaults.standard.set(defaultSelection.palette.rawValue, forKey: kPaletteStyle)
        UserDefaults.standard.synchronize()
        return defaultSelection
      }

      if let a = UserDefaults.standard.value(forKey: kAppearanceStyle) as? Int,
        let p = UserDefaults.standard.value(forKey: kPaletteStyle) as? Int,
        let appearance = AppearanceStyle(rawValue: a),
        let palette = PaletteStyle(rawValue: p)
      {
        return ThemeSelection(appearance: appearance, palette: palette)
      }

      // Migration from legacy ThemeStyle if selection not present
      let legacyRaw =
        (UserDefaults.standard.value(forKey: kThemeStyle) as? Int) ?? ThemeStyle.system.rawValue
      let legacy = ThemeStyle(rawValue: legacyRaw) ?? .system
      let migrated = selection(fromLegacy: legacy)
      UserDefaults.standard.set(migrated.appearance.rawValue, forKey: kAppearanceStyle)
      UserDefaults.standard.set(migrated.palette.rawValue, forKey: kPaletteStyle)
      UserDefaults.standard.synchronize()
      return migrated
    }
    set {
      _current = nil
      UserDefaults.standard.set(newValue.appearance.rawValue, forKey: kAppearanceStyle)
      UserDefaults.standard.set(newValue.palette.rawValue, forKey: kPaletteStyle)
      // Keep legacy style in sync for compatibility checks elsewhere
      let legacy = legacyStyle(fromSelection: newValue)
      UserDefaults.standard.set(legacy.rawValue, forKey: kThemeStyle)
      UserDefaults.standard.synchronize()
      applySystemAppearance(newValue.appearance)
    }
  }

  static func apply(option: ThemeOption) {
    let selection = option.selection
    currentSelection = selection
  }

  static var currentThemeStyle: ThemeStyle {
    get {
      let selection = currentSelection
      return legacyStyle(fromSelection: selection)
    }
    set {
      // Accept legacy writes and translate to new selection
      let selection = selection(fromLegacy: newValue)
      currentSelection = selection
    }
  }

  private static var _current: ThemeProtocol!
  static var current: ThemeProtocol {
    if let theme = _current { return theme }
    switch currentSelection.palette {
    case .alt:
      _current = SoftLightTheme()
    case .coffeeWithMilk:
      _current = CoffeeWithMilkTheme()
    case .standard:
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
          // Alt palette should adapt to system appearance
          window.overrideUserInterfaceStyle = .unspecified
        case .darkAlt:
          // Force dark appearance for Alt palette
          window.overrideUserInterfaceStyle = .dark
        case .coffeeWithMilk:
          // Allow dynamic colors in CoffeeWithMilk theme to adapt to system
          window.overrideUserInterfaceStyle = .unspecified
        case .coffeeWithMilkLight:
          // Force light appearance for CoffeeWithMilk palette
          window.overrideUserInterfaceStyle = .light
        case .coffeeWithMilkDark:
          // Force dark appearance for CoffeeWithMilk palette
          window.overrideUserInterfaceStyle = .dark
        case .dark:
          window.overrideUserInterfaceStyle = .dark
        case .system:
          window.overrideUserInterfaceStyle = .unspecified
        }
      }
    }
  }

  private static func applySystemAppearance(_ appearance: AppearanceStyle) {
    DispatchQueue.main.async {
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first
      {
        switch appearance {
        case .light: window.overrideUserInterfaceStyle = .light
        case .dark: window.overrideUserInterfaceStyle = .dark
        case .system: window.overrideUserInterfaceStyle = .unspecified
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
    if currentSelection.appearance == .system {
      let detectedTheme = detectSystemTheme()
      applySystemTheme(detectedTheme)
    }
  }

  // Apply current theme on app launch
  static func applyCurrentTheme() {
    let appearance = currentSelection.appearance
    switch appearance {
    case .system:
      let detectedTheme = detectSystemTheme()
      applySystemTheme(detectedTheme)
    case .light:
      applySystemAppearance(.light)
    case .dark:
      applySystemAppearance(.dark)
    }
  }
}

// MARK: - Legacy <-> New mapping helpers
private func legacyStyle(fromSelection selection: ThemeSelection) -> ThemeStyle {
  switch (selection.appearance, selection.palette) {
  case (.system, .standard): return .system
  case (.light, .standard): return .light
  case (.dark, .standard): return .dark
  case (.system, .alt): return .lightAlt
  case (.light, .alt): return .lightAlt
  case (.dark, .alt): return .darkAlt
  case (.system, .coffeeWithMilk): return .coffeeWithMilk
  case (.light, .coffeeWithMilk): return .coffeeWithMilkLight
  case (.dark, .coffeeWithMilk): return .coffeeWithMilkDark
  }
}

private func selection(fromLegacy style: ThemeStyle) -> ThemeSelection {
  switch style {
  case .system: return ThemeSelection(appearance: .system, palette: .standard)
  case .light: return ThemeSelection(appearance: .light, palette: .standard)
  case .dark: return ThemeSelection(appearance: .dark, palette: .standard)
  case .lightAlt: return ThemeSelection(appearance: .system, palette: .alt)
  case .darkAlt: return ThemeSelection(appearance: .dark, palette: .alt)
  case .coffeeWithMilk: return ThemeSelection(appearance: .system, palette: .coffeeWithMilk)
  case .coffeeWithMilkLight: return ThemeSelection(appearance: .light, palette: .coffeeWithMilk)
  case .coffeeWithMilkDark: return ThemeSelection(appearance: .dark, palette: .coffeeWithMilk)
  }
}

enum ThemeStyle: Int, CaseIterable {
  case light = 0
  case dark = 1
  case system = 2
  case lightAlt = 3
  case darkAlt = 7
  case coffeeWithMilk = 4
  case coffeeWithMilkLight = 5
  case coffeeWithMilkDark = 6

  var themeName: String {
    switch self {
    case .light: return R.string.global.lightThemeName()
    case .dark: return R.string.global.darkThemeName()
    case .system: return R.string.global.systemThemeName()
    case .lightAlt: return R.string.global.lightAltThemeName()
    case .darkAlt: return R.string.global.darkAltThemeName()
    case .coffeeWithMilk: return R.string.global.coffeeWithMilkThemeName()
    case .coffeeWithMilkLight: return R.string.global.coffeeWithMilkLightThemeName()
    case .coffeeWithMilkDark: return R.string.global.coffeeWithMilkDarkThemeName()
    }
  }

  // Control which theme options appear in the selection UI
  static var allCases: [ThemeStyle] {
    return [
      .coffeeWithMilk,
      .coffeeWithMilkLight,
      .coffeeWithMilkDark,
    ]
  }
}

struct AssetTheme: ThemeProtocol {
  private let logger = AppLogger.forType(AssetTheme.self)

  private func color(_ name: String, fallback: UIColor) -> UIColor {
    guard let color = UIColor(named: name) else {
      logger.error("Color '\(name)' not found in Assets.xcassets, using fallback")
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

  var tabBarUnselectedTint: UIColor {
    color("TabBarUnselectedTint", fallback: .secondaryLabel)
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
  private let logger = AppLogger.forType(SoftLightTheme.self)

  private func color(_ name: String, fallback: UIColor) -> UIColor {
    guard let color = UIColor(named: name) else {
      logger.error("Color '\(name)' not found in Assets.xcassets, using fallback")
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

  var tabBarUnselectedTint: UIColor {
    // Use secondary text tone for unselected items for clarity
    color("TabBarUnselectedTintAlt", fallback: UIColor(red: 90, green: 98, blue: 110))
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

// Light theme inspired by coffee with milk tones
struct CoffeeWithMilkTheme: ThemeProtocol {

  private func color(_ name: String, fallback: UIColor) -> UIColor {
    guard let color = UIColor(named: name) else {
      return fallback
    }
    return color
  }

  // Deep coffee for primary text
  var primaryText: UIColor {
    color("PrimaryTextCoffeeMilk", fallback: UIColor(red: 62, green: 39, blue: 35))
  }

  // Creamy milk background
  var primaryBackground: UIColor {
    color("PrimaryBackgroundCoffeeMilk", fallback: UIColor(red: 255, green: 248, blue: 231))
  }

  // Medium latte accent for secondary text
  var secondaryText: UIColor {
    color("SecondaryTextCoffeeMilk", fallback: UIColor(red: 109, green: 76, blue: 65))
  }

  // Light beige for grouped backgrounds
  var secondaryBackground: UIColor {
    color("SecondaryBackgroundCoffeeMilk", fallback: UIColor(red: 245, green: 238, blue: 230))
  }

  // Cappuccino accent for controls
  var tabBarTint: UIColor {
    // Use asset-defined deep coffee tone to ensure visibility
    color("TabBarTintCoffeeMilk", fallback: UIColor(red: 62, green: 39, blue: 35))
  }

  var tabBarUnselectedTint: UIColor {
    // Visible, but less prominent than selected
    let asset =
      UIColor(named: "TabBarUnselectedTintCoffeeMilk") ?? UIColor(red: 109, green: 76, blue: 65)
    return asset
  }

  var cellBackground: UIColor {
    color("CellBackgroundCoffeeMilk", fallback: UIColor(red: 255, green: 252, blue: 245))
  }

  var navBarBackground: UIColor {
    color("NavBarBackgroundCoffeeMilk", fallback: UIColor(red: 255, green: 253, blue: 247))
  }

  var navBarText: UIColor {
    color("NavBarTextCoffeeMilk", fallback: UIColor(red: 62, green: 39, blue: 35))
  }
}
