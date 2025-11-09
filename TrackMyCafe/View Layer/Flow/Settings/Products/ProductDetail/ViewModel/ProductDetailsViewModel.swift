//
//  ProductDetailsViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 09.11.2025.
//

import Foundation

final class ProductDetailsViewModel: ProductDetailsViewModelType, Loggable {
  private var model: ProductsPriceModel
  private let dataService: ProductPriceDataServiceProtocol

  var productName: String { model.name }
  var productPrice: Double { model.price }

  init(model: ProductsPriceModel, dataService: ProductPriceDataServiceProtocol) {
    self.model = model
    self.dataService = dataService
  }

  func validate(name: String?, priceText: String?) -> Bool {
    guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return false
    }
    guard let price = parsedPrice(from: priceText), price >= 0 else { return false }
    return true
  }

  func parsedPrice(from text: String?) -> Double? {
    guard let text = text, !text.isEmpty else { return nil }
    let formatter = NumberFormatter()
    formatter.locale = Locale.current
    formatter.numberStyle = .decimal
    if let number = formatter.number(from: text)?.doubleValue { return number }
    return Double(text.replacingOccurrences(of: ",", with: "."))
  }

  @MainActor
  func saveProductPrice(name: String?, price: Double?) async throws {
    let nameValue = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let priceValue = price ?? 0.0

    model.name = nameValue
    model.price = priceValue

    if model.id.isEmpty {
      model.id = UUID().uuidString
      do {
        try await dataService.saveProductPrice(model)
        logger.notice("Product price \(model.id) saved successfully")
      } catch {
        logger.error("Failed to save product price \(model.id)")
        throw error
      }
    } else {
      await dataService.updateProductPrice(model, name: nameValue, price: priceValue)
      logger.notice("Product price \(model.id) updated successfully")
    }
  }
}