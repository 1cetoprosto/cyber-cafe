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

  static var dynamicDomain: String {
    #if DEV
      return "kvit1.page.link"
    #else
      return "kvit.page.link"
    #endif
  }

  //MARK: - Android App
  static let androidBundle = "com.kvit.adtd.online"
  static let androidVersion = "62"
}

// other colors
let gray600 = UIColor(hex: "#757575")
let lighterGray = UIColor(hex: "#dddddd")
let veryLightGray = UIColor(hex: "#F0F0F0")
let darkerBlue = UIColor(hex: "#0099cc")
let grayNormal = UIColor(hex: "#9D9FA2")
let materialGREEN = UIColor(hex: "#2aa621")
let materialRED = UIColor(hex: "#ff6e6e")

// notifications
extension Notification.Name {
  static let adminInfoReload = Notification.Name("adminInfoReloadNotification")
  static let doctorsInfoReload = Notification.Name("doctorsInfoReloadNotification")
  static let techniciansInfoReload = Notification.Name("techniciansInfoReloadNotification")
  static let cadcamsInfoReload = Notification.Name("cadcamsInfoReload")
  static let castersInfoReload = Notification.Name("castersInfoReload")
  static let mainElementsInfoReload = Notification.Name("mainElementsInfoReload")
  static let extraElementsInfoReload = Notification.Name("extraElementsInfoReload")
  static let elementTypesInfoReload = Notification.Name("elementTypesInfoReload")
  static let settingsInfoReload = Notification.Name("settingsInfoReload")
  static let subscriptionInfoReload = Notification.Name("subscriptionInfoReload")
  static let ordersInfoReload = Notification.Name("ordersInfoReloadNotification")
  static let commentsInfoReload = Notification.Name("commentsInfoReloadNotification")
  static let logsInfoReload = Notification.Name("logsInfoReload")
  static let closeInfoView = Notification.Name("closeInfoViewNotification")
  static let saveInfoViewStatus = Notification.Name("saveInfoViewStatusNotification")
  static let closeTechicianAlert = Notification.Name("closeTechicianAlertNotification")
  static let saveTechicianAlertStatus = Notification.Name("saveTechicianAlertStatusNotification")
  static let groupEditorClose = Notification.Name("groupEditorCloseNotification")
}

enum Gender: Int {
  case male = 0
  case female
  case none

  var name: String {
    switch self {
    case .male: return R.string.global.genderMale()
    case .female: return R.string.global.genderFemale()
    case .none: return R.string.global.genderNoSpecified()
    }
  }
}

// Firebase refs
enum Refs: String {
  case users = "Users"
  case doctors = "Doctors"
  case technicians = "Technicians"
  case avatars = "Avatars"
  case comments = "Comments"
  case photos = "Photo"
  case audio = "Audio"
  case cadcams = "CadCams"
  case casters = "Casters"
  case mainElements = "MainElements"
  case extraElements = "ExtraElements"
  case elementTypes = "ElementTypes"
  case settings = "Settings"
  case subscription = "Subscription"
  case orders = "Orders"
  case logs = "Logs"
  case roles = "Roles"
}

// Links
let facebookGroup = ""  //"https://www.facebook.com/groups/1194517203901210/"
let dtLabEmail = "1cetoprosto@gmail.com"
let dtLabEmail2 = "leonid.kvit@gmail.com"

//enum Color: String, CaseIterable {
//    case master3d = "VITA 3DMaster"
//    case classic = "VITA classic"
//    var info: (code: Int, array: [String]) {
//        switch self {
//        case .master3d:
//            return (0, Subcolor3D.allCases.map{$0.rawValue})
//        case .classic:
//            return (1, Subcolor.allCases.map{$0.rawValue})
//        }
//    }
//}
//
//enum Subcolor: String, CaseIterable {
//    case bl1 = "BL1"
//    case bl2 = "BL2"
//    case bl3 = "BL3"
//    case bl4 = "BL4"
//    case a1 = "A1"
//    case a2 = "A2"
//    case a3 = "A3"
//    case a35 = "A3,5"
//    case a4 = "A4"
//    case b1 = "B1"
//    case b2 = "B2"
//    case b3 = "B3"
//    case b4 = "B4"
//    case c1 = "C1"
//    case c2 = "C2"
//    case c3 = "C3"
//    case c4 = "C4"
//    case d2 = "D2"
//    case d3 = "D3"
//    case d4 = "D4"
//}
//
//enum Subcolor3D: String, CaseIterable {
//    case bl1 = "BL1"
//    case bl2 = "BL2"
//    case bl3 = "BL3"
//    case bl4 = "BL4"
//    case m1 = "1M1"
//    case m2 = "1M2"
//    case l1 = "2L1.5"
//    case l2 = "2L2.5"
//    case m3 = "2M1"
//    case m4 = "2M2"
//    case m5 = "2M3"
//    case r1 = "2R1.5"
//    case r2 = "2R2.5"
//    case l3 = "3L1.5"
//    case l4 = "3L2.5"
//    case m6 = "3M1"
//    case m7 = "3M2"
//    case m8 = "3M3"
//    case r3 = "3R1.5"
//    case r4 = "3R2.5"
//    case l5 = "4L1.5"
//    case l6 = "4L2.5"
//    case m9 = "4M1"
//    case m10 = "4M2"
//    case m11 = "4M3"
//    case r5 = "4R1.5"
//    case r6 = "4R2.5"
//    case m12 = "5M1"
//    case m13 = "5M2"
//    case m14 = "5M3"
//}

enum OrderState: Int {
  case open = 0
  case paid = 1
  case inDebt = 2
}

enum ThemeColor: Int {
  case dark = 0
  case normal
  case accent
  case white
}

struct Constants {

  static var ZeroPrice: String {
    return "0\(Locale.current.decimalSeparator ?? ".")0"
  }
}
