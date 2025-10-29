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

  init(_ data: [String: AnyObject]) {
    self.createdDate = Date(timeIntervalSince1970: data[FirebaseFields.createdDate] as? Double ?? 0)
    self.updatedDate = Date(timeIntervalSince1970: data[FirebaseFields.updatedDate] as? Double ?? 0)
    self.currencyName = (data[SettingsFields.currencyName] as? String) ?? DefaultValues.currencyName
    self.currencySymbol = (data[SettingsFields.currencySymbol] as? String) ?? DefaultValues.currencySymbol
    self.imageUrl = (data[SettingsFields.imageUrl] as? String)?.nilIfEmpty
    self.imageThumbnailUrl = (data[SettingsFields.imageThumbnailUrl] as? String)?.nilIfEmpty
    self.universalComment = (data[SettingsFields.universalComment] as? String)?.nilIfEmpty
    self.isAllowed = (data[SettingsFields.isAllowed] as? Bool) ?? true
  }

  func forDatabase() -> [String: Any] {
    var values: [String: Any] = [
      FirebaseFields.createdDate: createdDate.interval,
      FirebaseFields.updatedDate: createdDate.interval,
      SettingsFields.currencyName: currencyName,
      SettingsFields.currencySymbol: currencySymbol,
      SettingsFields.isAllowed: isAllowed,
    ]
    if let value = imageUrl {
      values[SettingsFields.imageUrl] = value
    }
    if let value = imageThumbnailUrl {
      values[SettingsFields.imageThumbnailUrl] = value
    }
    if let value = universalComment {
      values[SettingsFields.universalComment] = value
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
