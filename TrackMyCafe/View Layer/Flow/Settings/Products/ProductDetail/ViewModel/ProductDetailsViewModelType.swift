//
//  ProductDetailsViewModelType.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 09.11.2025.
//

import Foundation

protocol ProductDetailsViewModelType: AnyObject {
    var productName: String { get }
    var productPrice: Double { get }
    var currentRecipe: [RecipeItemModel] { get }
    var allIngredients: [IngredientModel] { get }
    
    var onRecipeChanged: (() -> Void)? { get set }
    var onIngredientsLoaded: (() -> Void)? { get set }
    
    func validate(name: String?, priceText: String?) -> Bool
    func parsedPrice(from text: String?) -> Double?
    func saveProductPrice(name: String?, price: Double?) async throws
    
    func fetchIngredients() async
    func hasIngredient(_ ingredient: IngredientModel) -> Bool
    func addRecipeItem(ingredient: IngredientModel, quantity: Double, overwrite: Bool)
    func removeRecipeItem(at index: Int)
    func updateRecipeItem(at index: Int, quantity: Double)
}
