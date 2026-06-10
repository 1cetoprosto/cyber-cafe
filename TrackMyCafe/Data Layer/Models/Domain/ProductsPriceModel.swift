//
//  ProductsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct ProductsPriceModel {
    var id: String
    var name: String
    var price: Double
    var categoryId: String?
    var recipe: [RecipeItemModel]
    var imagePath: String?
    
    init(
        id: String,
        name: String,
        price: Double,
        categoryId: String? = nil,
        recipe: [RecipeItemModel] = [],
        imagePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.categoryId = categoryId
        self.recipe = recipe
        self.imagePath = imagePath
    }
    
    init(realmModel: RealmProductsPriceModel) {
        self.id = realmModel.id
        self.name = realmModel.name
        self.price = realmModel.price
        self.categoryId = nil
        self.recipe = realmModel.recipe.map { RecipeItemModel(realmModel: $0) }
        self.imagePath = nil
    }
    
    init(firebaseModel: FIRProductsPriceModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.price = firebaseModel.price
        self.categoryId = firebaseModel.categoryId
        self.recipe = firebaseModel.recipe.map { RecipeItemModel(firebaseModel: $0) }
        self.imagePath = firebaseModel.imagePath
    }
}
