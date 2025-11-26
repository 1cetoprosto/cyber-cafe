//
//  SettingsManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 18.05.2024.
//

import Foundation

class SettingsManager {
  static let shared = SettingsManager()

  private init() {}

  // Constants for UserDefaults keys - using existing constants from UserDefaultsKeys
  private let languageKey = UserDefaultsKeys.language
  private let themeKey = UserDefaultsKeys.theme
  private let onlineKey = UserDefaultsKeys.online

  func saveLanguage(_ language: String) {
    UserDefaults.standard.set(language, forKey: UserDefaultsKeys.language)
  }

  func loadLanguage() -> String {
    return UserDefaults.standard.string(forKey: UserDefaultsKeys.language) ?? DefaultValues.defaultLanguage
  }

  func setAppLanguage(_ languageCode: String) {
    UserDefaults.standard.set([languageCode], forKey: UserDefaultsKeys.appleLanguages)
    UserDefaults.standard.synchronize()
    saveLanguage(languageCode)
    //Bundle.setLanguage(languageCode: languageCode)
  }

  func saveTheme(_ theme: String) {
      UserDefaults.standard.set(theme, forKey: UserDefaultsKeys.theme)
  }

  func loadTheme() -> String {
      if let saved = UserDefaults.standard.string(forKey: UserDefaultsKeys.theme) {
        return saved
      }
      // Fallback to current selection's display name
      let option = ThemeOption.allCases.first(where: { $0.selection.appearance == Theme.currentSelection.appearance && $0.selection.palette == Theme.currentSelection.palette })
      return option?.displayName ?? Theme.currentThemeStyle.themeName
  }

  func saveOnline(_ isOn: Bool) {
    UserSession.current.saveOnline(isOn)
  }

  func loadOnline() -> Bool {
    return UserSession.current.hasOnlineVersion
  }

  func loadUserEmail() -> String {
    return UserSession.current.userEmail ?? "Not Autorized"
  }
}
