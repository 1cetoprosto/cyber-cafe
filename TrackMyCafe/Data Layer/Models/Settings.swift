//
//  Settings.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation

class Settings: CustomStringConvertible {

  var createdDate: Date
  var updatedDate: Date

  var currencyName: String
  var currencySymbol: String
  var imageUrl: String?
  var imageThumbnailUrl: String?
  var universalComment: String?
  var isAllowed: Bool

  init(
    currencyName: String = DefaultValues.currencyName,
    currencySymbol: String = DefaultValues.currencySymbol
  ) {
    self.currencyName = currencyName
    self.currencySymbol = currencySymbol
    self.imageUrl = nil
    self.imageThumbnailUrl = nil
    self.universalComment = nil
    self.isAllowed = false

    self.createdDate = Date()
    self.updatedDate = Date()
  }

  init?(_ data: [String: Any]) {
    guard
      let createdDate = data[FirebaseFields.createdDate] as? Double,
      let updateDate = data[FirebaseFields.updatedDate] as? Double
    else { return nil }
    self.createdDate = Date(timeIntervalSince1970: createdDate)
    self.updatedDate = Date(timeIntervalSince1970: updateDate)

    self.currencyName = (data["currencyName"] as? String) ?? DefaultValues.currencyName
    self.currencySymbol = (data["currencySymbol"] as? String) ?? DefaultValues.currencySymbol
    self.imageUrl = (data["imageUrl"] as? String)?.nilIfEmpty
    self.imageThumbnailUrl = (data["imageThumbnailUrl"] as? String)?.nilIfEmpty
    self.universalComment = (data["universalComment"] as? String)?.nilIfEmpty
    self.isAllowed = (data["isAllowed"] as? Bool) ?? true
  }

  func forDatabase() -> [String: Any] {
    var values: [String: Any] = [
      FirebaseFields.createdDate: createdDate.interval,
      FirebaseFields.updatedDate: createdDate.interval,
      "currencyName": currencyName,
      "currencySymbol": currencySymbol,
      "isAllowed": isAllowed,
    ]
    if let value = imageUrl {
      values["imageUrl"] = value
    }
    if let value = imageThumbnailUrl {
      values["imageThumbnailUrl"] = value
    }
    if let value = universalComment {
      values["universalComment"] = value
    }
    return values
  }

  func copy() -> Settings {
    let newElement = Settings()
    newElement.createdDate = self.createdDate
    newElement.updatedDate = self.updatedDate

    newElement.currencyName = self.currencyName
    newElement.currencySymbol = self.currencySymbol
    newElement.imageUrl = self.imageUrl
    newElement.imageThumbnailUrl = self.imageThumbnailUrl
    newElement.universalComment = self.universalComment
    newElement.isAllowed = self.isAllowed

    return newElement
  }
}
