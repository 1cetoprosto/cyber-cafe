//
//  ProductDetailsViewModelType.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 09.11.2025.
//

import Foundation

protocol ProductDetailsViewModelType {
  var productName: String { get }
  var productPrice: Double { get }

  func validate(name: String?, priceText: String?) -> Bool
  func parsedPrice(from text: String?) -> Double?
  func saveProductPrice(name: String?, price: Double?) async throws
}