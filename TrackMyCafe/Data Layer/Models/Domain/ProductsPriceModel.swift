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
    var recipe: [RecipeItemModel]
    
    init(id: String, name: String, price: Double, recipe: [RecipeItemModel] = []) {
        self.id = id
        self.name = name
        self.price = price
        self.recipe = recipe
    }
    
    init(realmModel: RealmProductsPriceModel) {
        self.id = realmModel.id
        self.name = realmModel.name
        self.price = realmModel.price
        self.recipe = realmModel.recipe.map { RecipeItemModel(realmModel: $0) }
    }
    
    init(firebaseModel: FIRProductsPriceModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.price = firebaseModel.price
        self.recipe = firebaseModel.recipe.map { RecipeItemModel(firebaseModel: $0) }
    }
}

