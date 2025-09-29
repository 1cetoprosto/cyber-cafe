//
//  Constants.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import UIKit

struct Config {

  static var associatedDomain: String {
    #if DEV
      return "https://kvit1.page.link"
    #else
      return "https://kvit.page.link"
    #endif
  }

  //MARK: - Android App
  static let androidBundle = "com.kvit.adtd.online"
  static let androidVersion = "62"
}

// notifications
extension Notification.Name {
  static let adminInfoReload = Notification.Name("adminInfoReloadNotification")
  static let techniciansInfoReload = Notification.Name("techniciansInfoReloadNotification")
  static let settingsInfoReload = Notification.Name("settingsInfoReload")
  static let subscriptionInfoReload = Notification.Name("subscriptionInfoReload")
  static let ordersInfoReload = Notification.Name("ordersInfoReloadNotification")
  static let logsInfoReload = Notification.Name("logsInfoReload")
}

// Firebase refs
enum Refs: String {
  case users = "Users"
  case technicians = "Technicians"
  case avatars = "Avatars"
  case comments = "Comments"
  case photos = "Photo"
  case audio = "Audio"
  case settings = "Settings"
  case subscription = "Subscription"
  case logs = "Logs"
  case orders = "Orders"
}

// MARK: - UI Constants
struct UIConstants {
  // Common spacing values
  static let standardSpacing: CGFloat = 10
  static let standardPadding: CGFloat = 16
  static let largeSpacing: CGFloat = 20
  static let smallSpacing: CGFloat = 5

  // Common heights
  static let buttonHeight: CGFloat = 50
  static let headerHeight: CGFloat = 60
  static let profileImageSize: CGFloat = 150
  static let avatarSize: CGFloat = 100
  static let cellHeight: CGFloat = 50
  static let sectionHeight: CGFloat = 100
  static let largeSectionHeight: CGFloat = 200
  static let extraLargeSectionHeight: CGFloat = 270

  // Common widths
  static let iconSize: CGFloat = 20
  static let imageSize: CGFloat = 80
  static let iconContainerSize: CGFloat = 30
  static let maxLabelWidth: CGFloat = 150
}

// MARK: - Keychain Keys
struct KeychainKeys {
    static let userId = "KeychainSessionUserId"
    static let userEmail = "KeychainSessionUserEmail"
    static let userRemember = "KeychainSessionUserRemember"
    static let useBioUser = "KeychainSessionUserUseBioUser"
    static let useBio = "KeychainSessionUserUseBio"
    static let hasOnlineVersion = "KeychainSessionUserHasOnlineVersion"
}

// MARK: - UserDefaults Keys
struct UserDefaultsKeys {
    static let language = "settings.language"
    static let theme = "settings.theme"
    static let online = "settings.online"
    static let themeStyle = "kThemeStyle"
    static let firstLaunch = "kFirstLaunch"
    static let subscriptionNextPaymentDate = "kUserSubscriptionNextPaymentDate"
    static let subscriptionIsPremiumPlan = "kUserSubscriptionIsPremiumPlan"
    static let appleLanguages = "AppleLanguages"
}

// MARK: - Firebase Collections
struct FirebaseCollections {
  static let users = "users"
  static let roles = "roles"
  static let admins = "admins"
  static let technicians = "technicians"
  static let productOfOrders = "productOfOrders"
  static let orders = "orders"
  static let productsPrice = "productsPrice"
  static let costs = "costs"
  static let types = "types"
  static let subscriptions = "Subscriptions"
  static let info = ".info"
}

// MARK: - Firebase Document Fields
struct FirebaseFields {
  static let email = "email"
  static let firstName = "firstName"
  static let lastName = "lastName"
  static let middleName = "middleName"
  static let phone = "phone"
  static let address = "address"
  static let avatarUrl = "avatarUrl"
  static let avatarThumbnailUrl = "avatarThumbnailUrl"
  static let comment = "comment"
  static let firebaseRef = "firebaseRef"
  static let createdDate = "createdDate"
  static let updatedDate = "updatedDate"
  static let enabled = "enabled"
  static let role = "role"
  static let connected = "connected"
  static let timestamp = "timestamp"
  static let userRef = "userRef"
  static let dataRef = "dataRef"
  static let uid = "uid"
}

// MARK: - Cell Identifiers
struct CellIdentifiers {
  static let ordersCell = "idOrdersCell"
  static let costsCell = "idCostsCell"
  static let typesCell = "idTypeCell"
  static let productsCell = "idProductsCell"
  static let orderCell = "idOrderCell"
  static let personCell = "PersonTableViewCell"
  static let subscriptionCell = "SubscriptionCell"
}

// MARK: - System Images
struct SystemImages {
  static let globe = "globe"
  static let sunMax = "sun.max"
  static let envelopeFill = "envelope.fill"
  static let creditCardCircleFill = "creditcard.circle.fill"
  static let cupAndSaucerFill = "cup.and.saucer.fill"
  static let banknoteFill = "banknote.fill"
  static let person2Fill = "person.2.fill"
  static let icloudFill = "icloud.fill"
  static let takeoutbagAndCupAndStrawFill = "takeoutbag.and.cup.and.straw.fill"
  static let gearshape = "gearshape"
}

// MARK: - Asset Names
struct AssetNames {
  static let edit = "edit"
  static let delete = "delete"
  static let avatarPlaceholder = "avatarPlaceholder"
  static let exit = "exit"
}

// MARK: - Color Names
struct ColorNames {
  static let primaryText = "PrimaryText"
  static let primaryBackground = "PrimaryBackground"
  static let secondaryText = "SecondaryText"
  static let secondaryBackground = "SecondaryBackground"
  static let tabBarTint = "TabBarTint"
  static let cellBackground = "CellBackground"
  static let navBarBackground = "NavBarBackground"
  static let navBarText = "NavBarText"
}

// MARK: - File Extensions
struct FileExtensions {
  static let lock = "lock"
  static let note = "note"
  static let management = "management"
  static let jpeg = "jpeg"
  static let thumbnailJpeg = "_thumbnail.jpeg"
  static let plist = "plist"
  static let cer = "cer"
  static let m4a = "m4a"
}

// MARK: - Default Values
struct DefaultValues {
  static let currencyName = "Гривня"
  static let currencySymbol = "₴"
  static let defaultLanguage = "English"
  static let defaultOrderType = "Default"
  static let unknownVersion = "Unknown"
  static let unknownUser = "Unknown"
  static let adminFirstName = "Admin"
  static let dollarName = "Dollar"
  static let dollarSymbol = "$"
  static let trueString = "true"
  static let falseString = "false"
}

// Links
let supportEmail = "1cetoprosto@gmail.com"
