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

  // Constants for UserDefaults keys
  private let languageKey = "settings.language"
  private let themeKey = "settings.theme"
  private let onlineKey = "settings.online"

  func saveLanguage(_ language: String) {
    UserDefaults.standard.set(language, forKey: languageKey)
  }

  func loadLanguage() -> String {
    return UserDefaults.standard.string(forKey: languageKey) ?? "English"
  }

  func setAppLanguage(_ languageCode: String) {
    UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
    UserDefaults.standard.synchronize()
    saveLanguage(languageCode)
    //Bundle.setLanguage(languageCode: languageCode)
  }

  func saveTheme(_ theme: String) {
    UserDefaults.standard.set(theme, forKey: themeKey)
  }

  func loadTheme() -> String {
    return UserDefaults.standard.string(forKey: themeKey) ?? Theme.currentThemeStyle.themeName
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
