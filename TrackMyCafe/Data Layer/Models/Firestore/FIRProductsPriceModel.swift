//
//  FIRProductsPriceModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import FirebaseFirestoreSwift
import Foundation

struct FIRProductsPriceModel: Codable {
  @DocumentID var id: String?
  var name: String = ""
  var price: Double = 0.0
  var recipe: [FIRRecipeItemModel] = []

  init(dataModel: ProductsPriceModel) {
    self.id = dataModel.id
    self.name = dataModel.name
    self.price = dataModel.price
    self.recipe = dataModel.recipe.map { FIRRecipeItemModel(dataModel: $0) }
  }
}

//extension FIRProductsPriceModel {
//    static var empty = FIRProductsPriceModel(productsPriceModel: RealmProductsPriceModel())
//}
