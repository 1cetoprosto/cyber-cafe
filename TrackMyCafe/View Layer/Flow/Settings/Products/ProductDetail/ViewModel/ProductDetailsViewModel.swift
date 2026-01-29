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
  private let ingredientService: IngredientDataServiceProtocol

  var productName: String { model.name }
  var productPrice: Double { model.price }
  var currentRecipe: [RecipeItemModel] { model.recipe }
  var allIngredients: [IngredientModel] = []
  
  var onRecipeChanged: (() -> Void)?
  var onIngredientsLoaded: (() -> Void)?

  init(model: ProductsPriceModel, 
       dataService: ProductPriceDataServiceProtocol,
       ingredientService: IngredientDataServiceProtocol = DomainIngredientDataService.shared) {
    self.model = model
    self.dataService = dataService
    self.ingredientService = ingredientService
  }
  
  func fetchIngredients() async {
    do {
      let ingredients = try await ingredientService.fetchIngredients()
      self.allIngredients = ingredients
      await MainActor.run {
          self.onIngredientsLoaded?()
      }
    } catch {
      logger.error("Failed to fetch ingredients: \(error)")
    }
  }

  func addRecipeItem(ingredient: IngredientModel, quantity: Double) {
    guard quantity > 0 else { return }
    let item = RecipeItemModel(ingredientId: ingredient.id, ingredientName: ingredient.name, quantity: quantity, unit: ingredient.unit)
    model.recipe.append(item)
    onRecipeChanged?()
  }

  func removeRecipeItem(at index: Int) {
    guard index >= 0 && index < model.recipe.count else { return }
    model.recipe.remove(at: index)
    onRecipeChanged?()
  }

  func updateRecipeItem(at index: Int, quantity: Double) {
    guard index >= 0 && index < model.recipe.count else { return }
    var item = model.recipe[index]
    item.quantity = quantity
    model.recipe[index] = item
    onRecipeChanged?()
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