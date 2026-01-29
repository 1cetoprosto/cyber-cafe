//
//  Repository.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation
import RealmSwift
import os.log

class DomainDatabaseService: DomainDB {

  static let shared = DomainDatabaseService()
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!, category: "DomainDatabaseService")

  // Метод для перевірки, чи включений режим онлайн
  private func isOnlineModeEnabled() -> Bool {
    return SettingsManager.shared.loadOnline()
  }

  // MARK: - Ingredient Operations

  func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.ingredients, firModel: FIRIngredientModel.self
      ) { result in
        switch result {
        case .success(let firModels):
          let models = firModels.map { IngredientModel(firebaseModel: $0.1) }
          completion(models)
        case .failure(let error):
          self.logger.error(
            "Error fetching ingredients from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let models = RealmDatabaseService.shared.fetchIngredients().map {
        IngredientModel(realmModel: $0)
      }
      completion(models)
    }
  }

  func saveIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      let firModel = FIRIngredientModel(dataModel: model)
      FirestoreDatabaseService.shared.create(
        firModel: firModel, collection: FirebaseCollections.ingredients
      ) { result in
        switch result {
        case .success:
          completion(true)
        case .failure(let error):
          self.logger.error("Failed to save ingredient to Firestore: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      let realmModel = RealmIngredientModel(dataModel: model)
      RealmDatabaseService.shared.save(model: realmModel)
      completion(true)
    }
  }

  func deleteIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.delete(
        collection: FirebaseCollections.ingredients, documentId: model.id
      ) { result in
        switch result {
        case .success:
          completion(true)
        case .failure(let error):
          self.logger.error("Failed to delete ingredient from Firestore: \(error)")
          completion(false)
        }
      }
    } else {
      guard let realmModel = RealmDatabaseService.shared.fetchIngredient(byId: model.id) else {
        completion(false)
        return
      }
      RealmDatabaseService.shared.delete(model: realmModel)
      completion(true)
    }
  }

  // MARK: - Product Operations

  func updateProduct(
    model: ProductOfOrderModel, date: Date, name: String, quantity: Int, price: Double, sum: Double
  ) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      var updatedModel = FIRProductModel(dataModel: model)
      updatedModel.date = date
      updatedModel.name = name
      updatedModel.quantity = quantity
      updatedModel.price = price
      updatedModel.amount = sum

      FirestoreDatabaseService.shared.update(
        firModel: updatedModel, collection: FirebaseCollections.productOfOrders,
        documentId: model.id
      ) { result in
        switch result {
        case .success():
          self.logger.info("Order product updated successfully in Firestore database")
        case .failure(let error):
          self.logger.error(
            "Failed to update order product in Firestore database: \(error.localizedDescription)")
        }
      }
    } else {
      guard
        let updatedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmProductModel.self, id: model.id)
      else { return }
      RealmDatabaseService.shared.updateProduct(
        model: updatedModel, date: date, name: name, quantity: quantity, price: price, sum: sum)
    }
  }

  func fetchProduct(forDate date: Date, completion: @escaping ([ProductOfOrderModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self
      ) { result in
        switch result {
        case .success(let firProducts):
          let ordersProduct = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
          completion(ordersProduct)
        case .failure(let error):
          self.logger.error("Error fetching products from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let ordersProduct = RealmDatabaseService.shared.fetchProducts()
        .map { ProductOfOrderModel(realmModel: $0) }
      completion(ordersProduct)
    }
  }

  func fetchProduct(
    forDate date: Date, withName name: String, completion: @escaping (ProductOfOrderModel?) -> Void
  ) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self
      ) { result in
        switch result {
        case .success(let firProducts):
          let ordersProduct = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
          let filteredProduct = ordersProduct.first { $0.date == date && $0.name == name }
          completion(filteredProduct)
        case .failure(let error):
          self.logger.error("Error fetching products from Firestore: \(error.localizedDescription)")
          completion(nil)
        }
      }
    } else {
      if let product = RealmDatabaseService.shared.fetchProduct(forDate: date, withName: name) {
        completion(ProductOfOrderModel(realmModel: product))
      } else {
        completion(nil)
      }
    }
  }

  func fetchProduct(withOrderId id: String, completion: @escaping ([ProductOfOrderModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.productOfOrders, firModel: FIRProductModel.self
      ) { result in
        switch result {
        case .success(let firProducts):
          let ordersProduct = firProducts.map { ProductOfOrderModel(firebaseModel: $0.1) }
          let filteredProduct = ordersProduct.filter { $0.orderId == id }
          completion(filteredProduct)
        case .failure(let error):
          self.logger.error("Error fetching products from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let ordersProduct = RealmDatabaseService.shared.fetchProducts(withOrderId: id)
        .map { ProductOfOrderModel(realmModel: $0) }
      completion(ordersProduct)
    }
  }

  func saveProduct(order: ProductOfOrderModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.create(
        firModel: FIRProductModel(dataModel: order), collection: FirebaseCollections.productOfOrders
      ) { result in
        switch result {
        case .success:
          self.logger.info("Order product saved to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to save order product to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      let model = RealmProductModel(dataModel: order)
      model.id = UUID().uuidString
      RealmDatabaseService.shared.save(model: model)
      logger.log("Order product saved to Realm successfully")
      completion(true)
    }
  }

  func deleteProduct(order: ProductOfOrderModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.delete(
        collection: FirebaseCollections.productOfOrders, documentId: order.id
      ) {
        result in
        switch result {
        case .success:
          self.logger.info("Order product deleted to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to delete order product to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      guard
        let deletedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmProductModel.self, id: order.id)
      else { return }
      RealmDatabaseService.shared.delete(model: deletedModel)
      completion(true)
    }
  }

  // MARK: - Orders Operations

  func updateOrders(
    model: OrderModel, date: Date, type: String, total: Double, cashAmount: Double,
    cardAmount: Double
  ) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      var updatedModel = FIROrderModel(dataModel: model)
      updatedModel.date = date
      updatedModel.type = type
      updatedModel.sum = total
      updatedModel.cash = cashAmount
      updatedModel.card = cardAmount
      FirestoreDatabaseService.shared.update(
        firModel: updatedModel, collection: FirebaseCollections.orders, documentId: model.id
      ) { result in
        switch result {
        case .success():
          self.logger.info("Order updated successfully in Firestore database")
        case .failure(let error):
          self.logger.error(
            "Failed to update order in Firestore database: \(error.localizedDescription)")
        }
      }
    } else {
      guard let updatedModel = RealmDatabaseService.shared.fetchOrder(byId: model.id) else {
        return
      }
      RealmDatabaseService.shared.updateOrder(
        model: updatedModel, date: date, type: type, total: total, cashAmount: cashAmount,
        cardAmount: cardAmount)
    }
  }

  func fetchOrders(completion: @escaping ([OrderModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.orders, firModel: FIROrderModel.self
      ) {
        result in
        switch result {
        case .success(let firOrders):
          let orders = firOrders.map { OrderModel(firebaseModel: $1) }
          completion(orders)
        case .failure(let error):
          self.logger.error("Error fetching products from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let orders = RealmDatabaseService.shared.fetchOrders().map { OrderModel(realmModel: $0) }
      completion(orders)
    }
  }

  func fetchSectionsOfOrders(completion: @escaping ([(date: Date, items: [OrderModel])]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.orders, firModel: FIROrderModel.self
      ) {
        result in
        switch result {
        case .success(let firOrders):
          let calendar = Calendar.current
          let groupedOrders = Dictionary(
            grouping: firOrders.map { OrderModel(firebaseModel: $1) },
            by: { order -> Date in
              let dateComponents = calendar.dateComponents([.year, .month, .day], from: order.date)
              return calendar.date(from: dateComponents)!
            })
          let sections = groupedOrders.map { (date: $0.key, items: $0.value) }
            .sorted { $0.date < $1.date }
          completion(sections)
        case .failure(let error):
          self.logger.error("Error fetching orders from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let sections = RealmDatabaseService.shared.fetchOrderSections().map {
        (date: $0.date, items: $0.items.map { OrderModel(realmModel: $0) })
      }
      completion(sections)
    }
  }

  func fetchOrders(forId id: String, completion: @escaping (OrderModel?) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.orders, firModel: FIROrderModel.self
      ) {
        result in
        switch result {
        case .success(let firOrders):
          let orders = firOrders.map { OrderModel(firebaseModel: $1) }
          completion(
            orders.filter { $0.id == id }
              .first)
        case .failure(let error):
          self.logger.error("Error fetching orders from Firestore: \(error.localizedDescription)")
          completion(nil)
        }
      }
    } else {
      guard let order = RealmDatabaseService.shared.fetchOrder(byId: id) else { return }
      completion(OrderModel(realmModel: order))
    }
  }

  func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.create(
        firModel: FIROrderModel(dataModel: order), collection: FirebaseCollections.orders
      ) { result in
        switch result {
        case .success(let documentId):
          self.logger.info("Order saved to Firestore successfully")
          completion(documentId)
        case .failure(let error):
          self.logger.error(
            "Failed to save order to Firestore with error: \(error.localizedDescription)")
          completion(nil)
        }
      }
    } else {
      let model = RealmOrderModel(dataModel: order)
      model.id = UUID().uuidString
      RealmDatabaseService.shared.save(model: model)
      logger.log("Orders saved to Realm successfully")
      completion(model.id)
    }
  }

  func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.delete(
        collection: FirebaseCollections.orders, documentId: order.id
      ) { result in
        switch result {
        case .success:
          self.logger.info("Order deleted to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to delete order to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      guard
        let deletedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmOrderModel.self, id: order.id)
      else { return }
      RealmDatabaseService.shared.delete(model: deletedModel)
      completion(true)
    }
  }

  // MARK: - ProductsPrice Operations

  func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      var updatedModel = FIRProductsPriceModel(dataModel: model)
      updatedModel.name = name
      updatedModel.price = price
      FirestoreDatabaseService.shared.update(
        firModel: updatedModel, collection: FirebaseCollections.productsPrice,
        documentId: model.id
      ) { result in
        switch result {
        case .success():
          self.logger.info("Product price updated successfully in Firestore database")
        case .failure(let error):
          self.logger.error(
            "Failed to update product price in Firestore database: \(error.localizedDescription)")
        }
      }
    } else {
      guard let updatedModel = RealmDatabaseService.shared.fetchProductPrice(byId: model.id) else {
        return
      }
      RealmDatabaseService.shared.updateProductPrice(
        model: updatedModel, name: name, price: price, recipe: model.recipe)
    }
  }

  func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.productsPrice,
        firModel: FIRProductsPriceModel.self
      ) { result in
        switch result {
        case .success(let firProducts):
          let products = firProducts.map { ProductsPriceModel(firebaseModel: $1) }
          completion(products)
        case .failure(let error):
          self.logger.error("Error fetching products from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let productsPrices = RealmDatabaseService.shared.fetchProductPrices().map {
        ProductsPriceModel(realmModel: $0)
      }
      completion(productsPrices)
    }
  }

  func saveProductsPrice(productPrice: ProductsPriceModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.create(
        firModel: FIRProductsPriceModel(dataModel: productPrice),
        collection: FirebaseCollections.productsPrice
      ) { result in
        switch result {
        case .success(_):
          self.logger.info("Product price saved to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to save product price to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      RealmDatabaseService.shared.save(model: RealmProductsPriceModel(dataModel: productPrice))
      completion(true)
    }
  }

  func deleteProductsPrice(model: ProductsPriceModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.delete(
        collection: FirebaseCollections.productsPrice, documentId: model.id
      ) {
        result in
        switch result {
        case .success:
          self.logger.info("productsPrice deleted to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to productsPrice order to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      guard
        let deletedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmProductsPriceModel.self, id: model.id)
      else { return }
      RealmDatabaseService.shared.delete(model: deletedModel)
      completion(true)
    }
  }

  // MARK: - Cost Operations

  func updateCost(model: CostModel, date: Date, name: String, sum: Double) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      var updatedModel = FIRCostModel(dataModel: model)
      updatedModel.date = date
      updatedModel.name = name
      updatedModel.sum = sum
      FirestoreDatabaseService.shared.update(
        firModel: updatedModel, collection: FirebaseCollections.costs,
        documentId: model.id
      ) { result in
        switch result {
        case .success():
          self.logger.info("Cost updated successfully in Firestore database")
        case .failure(let error):
          self.logger.error(
            "Failed to update cost in Firestore database: \(error.localizedDescription)")
        }
      }
    } else {
      guard let updatedModel = RealmDatabaseService.shared.fetchCost(byId: model.id) else { return }
      RealmDatabaseService.shared.updateCost(model: updatedModel, date: date, name: name, sum: sum)
    }
  }

  func fetchCosts(completion: @escaping ([CostModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.costs, firModel: FIRCostModel.self
      ) {
        result in
        switch result {
        case .success(let firCosts):
          let costs = firCosts.map { CostModel(firebaseModel: $1) }
          completion(costs)
        case .failure(let error):
          self.logger.error("Error fetching costs from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let costs = RealmDatabaseService.shared.fetchCosts().map { CostModel(realmModel: $0) }
      completion(costs)
    }
  }

  func fetchSectionsOfCosts(completion: @escaping ([(date: Date, items: [CostModel])]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.costs, firModel: FIRCostModel.self
      ) {
        result in
        switch result {
        case .success(let firCosts):
          let calendar = Calendar.current
          let groupedCosts = Dictionary(
            grouping: firCosts.map { CostModel(firebaseModel: $1) },
            by: { cost -> Date in
              let dateComponents = calendar.dateComponents([.year, .month, .day], from: cost.date)
              return calendar.date(from: dateComponents)!
            })
          let sections = groupedCosts.map { (date: $0.key, items: $0.value) }
            .sorted { $0.date < $1.date }
          completion(sections)
        case .failure(let error):
          self.logger.error(
            "Error fetching costs Sections from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let sections = RealmDatabaseService.shared.fetchCostSections().map {
        (date: $0.date, items: $0.items.map { CostModel(realmModel: $0) })
      }
      completion(sections)
    }
  }

  func saveCost(model: CostModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.create(
        firModel: FIRCostModel(dataModel: model), collection: FirebaseCollections.costs
      ) { result in
        switch result {
        case .success(_):
          self.logger.info("Cost saved to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to save cost to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      RealmDatabaseService.shared.save(model: RealmCostModel(dataModel: model))
      logger.log("Cost saved to Realm successfully")
      completion(true)
    }
  }

  func deleteCost(model: CostModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.delete(
        collection: FirebaseCollections.costs, documentId: model.id
      ) { result in
        switch result {
        case .success:
          self.logger.info("costs deleted to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to delete costs order to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      guard
        let deletedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmCostModel.self, id: model.id)
      else { return }
      RealmDatabaseService.shared.delete(model: deletedModel)
      completion(true)
    }
  }

  // MARK: - Type Operations

  func updateType(model: TypeModel, type: String) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      var updatedModel = FIRTypeModel(dataModel: model)
      updatedModel.name = type
      FirestoreDatabaseService.shared.update(
        firModel: updatedModel, collection: FirebaseCollections.types,
        documentId: model.id
      ) { result in
        switch result {
        case .success():
          self.logger.info("Type updated successfully in Firestore database")
        case .failure(let error):
          self.logger.error(
            "Failed to update type in Firestore database: \(error.localizedDescription)")
        }
      }
    } else {
      guard
        let updatedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmTypeModel.self, id: model.id)
      else { return }
      RealmDatabaseService.shared.updateType(model: updatedModel, type: type)
    }
  }

  func fetchTypes(completion: @escaping ([TypeModel]) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.types, firModel: FIRTypeModel.self
      ) {
        result in
        switch result {
        case .success(let firTypes):
          let types = firTypes.map { TypeModel(firebaseModel: $1) }
          completion(types)
        case .failure(let error):
          self.logger.error("Error fetching types from Firestore: \(error.localizedDescription)")
          completion([])
        }
      }
    } else {
      let types = RealmDatabaseService.shared.fetchTypes().map { TypeModel(realmModel: $0) }
      completion(types)
    }
  }

  func saveType(model: TypeModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.create(
        firModel: FIRTypeModel(dataModel: model), collection: FirebaseCollections.types
      ) { result in
        switch result {
        case .success(_):
          self.logger.info("Types saved to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to save Types to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      RealmDatabaseService.shared.save(model: RealmTypeModel(dataModel: model))
      completion(true)
    }
  }

  func setDefaultType(model: TypeModel, isDefault: Bool) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.read(
        collection: FirebaseCollections.types, firModel: FIRTypeModel.self
      ) { result in
        switch result {
        case .success(let firTypes):
          let types = firTypes.map { TypeModel(firebaseModel: $1) }
          for t in types {
            var updated = FIRTypeModel(dataModel: t)
            updated.isDefault = (t.id == model.id) ? isDefault : false
            FirestoreDatabaseService.shared.update(
              firModel: updated, collection: FirebaseCollections.types, documentId: t.id
            ) { _ in }
          }
          self.logger.info("Default type updated in Firestore")
        case .failure(let error):
          self.logger.error(
            "Failed to update default type in Firestore: \(error.localizedDescription)")
        }
      }
    } else {
      let realmTypes = RealmDatabaseService.shared.fetchTypes()
      for rm in realmTypes {
        RealmDatabaseService.shared.updateTypeDefault(
          model: rm, isDefault: (rm.id == model.id) ? isDefault : false)
      }
      logger.log("Default type updated in Realm")
    }
  }

  func deleteType(model: TypeModel, completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.delete(
        collection: FirebaseCollections.types, documentId: model.id
      ) { result in
        switch result {
        case .success:
          self.logger.info("Types deleted to Firestore successfully")
          completion(true)
        case .failure(let error):
          self.logger.error(
            "Failed to delete types order to Firestore with error: \(error.localizedDescription)")
          completion(false)
        }
      }
    } else {
      guard
        let deletedModel = RealmDatabaseService.shared.fetchObjectById(
          ofType: RealmTypeModel.self, id: model.id)
      else { return }
      RealmDatabaseService.shared.delete(model: deletedModel)
      completion(true)
    }
  }

  // MARK: - delete Operations

  func deleteActiveDatabaseData(completion: @escaping (Bool) -> Void) {
    let isOnline = isOnlineModeEnabled()

    if isOnline {
      FirestoreDatabaseService.shared.deleteAllData { success in
        if success {
          self.logger.log("All data deleted successfully from Firestore database")
          completion(true)
        } else {
          self.logger.log("Failed to delete data from Firestore database")
          completion(false)
        }
      }
    } else {
      RealmDatabaseService.shared.deleteAllData { success in
        if success {
          self.logger.log("All data deleted successfully from Realm database")
          completion(true)
        } else {
          self.logger.log("Failed to delete data from Realm database")
          completion(false)
        }
      }
    }
  }

  // MARK: - general Operations

  var orderIdMap: [String: String] = [:]

  func transferDataFromFIRToRealm(completion: @escaping () -> Void) {
    let dispatchGroup = DispatchGroup()

    dispatchGroup.enter()
    RealmDatabaseService.shared.deleteAllData { success in
      dispatchGroup.leave()
    }

    dispatchGroup.enter()
    self.transferCollectionToRealm(
      collection: FirebaseCollections.orders,
      firModelType: FIROrderModel.self,
      domainModelInit: OrderModel.init(firebaseModel:),
      realmModelInit: RealmOrderModel.init(dataModel:)
    ) {
      dispatchGroup.leave()
    }

    dispatchGroup.notify(queue: .main) {
      dispatchGroup.enter()
      self.transferProductOfOrdersToRealm {
        dispatchGroup.leave()
      }

      dispatchGroup.enter()
      self.transferCollectionToRealm(
        collection: FirebaseCollections.costs,
        firModelType: FIRCostModel.self,
        domainModelInit: CostModel.init(firebaseModel:),
        realmModelInit: RealmCostModel.init(dataModel:)
      ) {
        dispatchGroup.leave()
      }

      dispatchGroup.enter()
      self.transferCollectionToRealm(
        collection: FirebaseCollections.productsPrice,
        firModelType: FIRProductsPriceModel.self,
        domainModelInit: ProductsPriceModel.init(firebaseModel:),
        realmModelInit: RealmProductsPriceModel.init(dataModel:)
      ) {
        dispatchGroup.leave()
      }

      dispatchGroup.enter()
      self.transferCollectionToRealm(
        collection: FirebaseCollections.types,
        firModelType: FIRTypeModel.self,
        domainModelInit: TypeModel.init(firebaseModel:),
        realmModelInit: RealmTypeModel.init(dataModel:)
      ) {
        dispatchGroup.leave()
      }

      dispatchGroup.enter()
      self.transferCollectionToRealm(
        collection: FirebaseCollections.ingredients,
        firModelType: FIRIngredientModel.self,
        domainModelInit: IngredientModel.init(firebaseModel:),
        realmModelInit: RealmIngredientModel.init(dataModel:)
      ) {
        dispatchGroup.leave()
      }

      dispatchGroup.notify(queue: .main) {
        completion()
      }
    }
  }

  func transferCollectionToRealm<FIRModel, DomainModel, RealmModel>(
    collection: String, firModelType: FIRModel.Type,
    domainModelInit: @escaping (FIRModel) -> DomainModel,
    realmModelInit: @escaping (DomainModel) -> RealmModel, completion: @escaping () -> Void
  ) where FIRModel: Codable, RealmModel: Object {
    DispatchQueue.global().async {
      FirestoreDatabaseService.shared.read(collection: collection, firModel: firModelType) {
        result in
        switch result {
        case .success(let firModels):
          let internalGroup = DispatchGroup()

          for (documentId, firModel) in firModels {
            internalGroup.enter()
            let domainModel = domainModelInit(firModel)
            let realmModel = realmModelInit(domainModel)

            RealmDatabaseService.shared.save(model: realmModel)
            if collection == FirebaseCollections.orders {
              let model = domainModel as! OrderModel
              self.orderIdMap[documentId] = model.id  // Використання id з OrderModel як Realm ID
            }
            internalGroup.leave()
          }

          internalGroup.notify(queue: .global()) {
            completion()
          }
        case .failure(let error):
          self.logger.error(
            "Failed to transfer collection \(collection) to Realm with error: \(error.localizedDescription)"
          )
          completion()
        }
      }
    }
  }

  func transferProductOfOrdersToRealm(completion: @escaping () -> Void) {
    self.transferCollectionToRealm(
      collection: FirebaseCollections.productOfOrders,
      firModelType: FIRProductModel.self,
      domainModelInit: { firModel in
        var domainModel = ProductOfOrderModel(firebaseModel: firModel)

        // Перевіряємо, чи існує відповідний ідентифікатор orders в словнику
        guard let orderId = firModel.orderId, let newOrderId = self.orderIdMap[orderId] else {
          self.logger.error("Missing order ID mapping for \(String(describing: firModel.orderId))")
          return domainModel
        }

        domainModel.orderId = newOrderId  // Встановлюємо правильний ідентифікатор
        return domainModel
      },
      realmModelInit: RealmProductModel.init(dataModel:)
    ) {
      completion()
    }
  }

  func transferDataFromRealmToFIR(completion: @escaping () -> Void) {
    let deleteDispatchGroup = DispatchGroup()
    let transferDispatchGroup = DispatchGroup()

    // Спочатку видаляємо всі дані з Firestore
    deleteDispatchGroup.enter()
    FirestoreDatabaseService.shared.deleteAllData { _ in
      deleteDispatchGroup.leave()
    }

    deleteDispatchGroup.notify(queue: .main) {
      // Після того, як всі дані видалені, починаємо перенесення даних з Realm у Firestore
      transferDispatchGroup.enter()
      self.transferCollectionToFIR(
        collection: FirebaseCollections.costs,
        realmModelType: RealmCostModel.self,
        domainModelInit: CostModel.init(realmModel:),
        firModelInit: FIRCostModel.init(dataModel:)
      ) {
        transferDispatchGroup.leave()
      }

      transferDispatchGroup.enter()
      self.transferCollectionToFIR(
        collection: FirebaseCollections.productsPrice,
        realmModelType: RealmProductsPriceModel.self,
        domainModelInit: ProductsPriceModel.init(realmModel:),
        firModelInit: FIRProductsPriceModel.init(dataModel:)
      ) {
        transferDispatchGroup.leave()
      }

      transferDispatchGroup.enter()
      self.transferCollectionToFIR(
        collection: FirebaseCollections.types,
        realmModelType: RealmTypeModel.self,
        domainModelInit: TypeModel.init(realmModel:),
        firModelInit: FIRTypeModel.init(dataModel:)
      ) {
        transferDispatchGroup.leave()
      }

      transferDispatchGroup.enter()
      self.transferCollectionToFIR(
        collection: FirebaseCollections.orders,
        realmModelType: RealmOrderModel.self,
        domainModelInit: OrderModel.init(realmModel:),
        firModelInit: FIROrderModel.init(dataModel:)
      ) {
        transferDispatchGroup.leave()
      }

      // Додаємо проміжну операцію для оновлення orderIdMap перед перенесенням productOfOrders
      transferDispatchGroup.notify(queue: .main) {
        // Всі order вже перенесені, тепер можемо переносити productOfOrders
        transferDispatchGroup.enter()
        self.transferProductOfOrdersToFIR {
          transferDispatchGroup.leave()
        }
      }

      transferDispatchGroup.notify(queue: .main) {
        RealmDatabaseService.shared.deleteAllData { _ in
          completion()
        }
      }
    }
  }

  func transferProductOfOrdersToFIR(completion: @escaping () -> Void) {
    self.transferCollectionToFIR(
      collection: FirebaseCollections.productOfOrders,
      realmModelType: RealmProductModel.self,
      domainModelInit: { realmModel in
        var domainModel = ProductOfOrderModel(realmModel: realmModel)

        // Перевіряємо, чи існує відповідний ідентифікатор orders в словнику
        if let newOrderId = self.orderIdMap[realmModel.orderId] {
          domainModel.orderId = newOrderId  // Встановлюємо правильний ідентифікатор
        }
        return domainModel
      },
      firModelInit: FIRProductModel.init(dataModel:)
    ) {
      completion()
    }
  }

  @MainActor
  func seedTestData(forDays days: Int) async {
    await withCheckedContinuation { continuation in
      self.deleteActiveDatabaseData { _ in
        continuation.resume()
      }
    }

    let typeHall = R.string.global.typeHall()
    let typeTakeaway = R.string.global.typeTakeaway()
    let typeDelivery = R.string.global.typeDelivery()
    let types: [TypeModel] = [
      TypeModel(id: UUID().uuidString, name: typeHall, isDefault: true),
      TypeModel(id: UUID().uuidString, name: typeTakeaway, isDefault: false),
      TypeModel(id: UUID().uuidString, name: typeDelivery, isDefault: false),
    ]

    for t in types {
      await withCheckedContinuation { continuation in
        self.saveType(model: t) { _ in
          continuation.resume()
        }
      }
    }

    let isUkrainian = Locale.current.languageCode == "uk"
    let catalog: [(uk: String, en: String, price: Double)] = [
      ("Еспресо", "Espresso", 8),
      ("Еспресо з молоком", "Espresso with milk", 10),
      ("Американо", "Americano", 8),
      ("Американо з молоком", "Americano with milk", 12),
      ("Капучіно", "Cappuccino", 15),
      ("Лате", "Latte", 20),
      ("Лате макіато", "Latte macchiato", 20),
      ("Айріш", "Irish", 14),
      ("Айріш великий", "Irish large", 16),
      ("Гарячий шоколад", "Hot chocolate", 12),
      ("Гарячий шоколад великий", "Hot chocolate large", 16),
      ("Какао", "Cocoa", 10),
      ("Дитяче лате", "Kids latte", 15),
      ("Чай", "Tea", 5),
      ("Айс лате", "Ice latte", 15),
    ]

    let products: [ProductsPriceModel] = catalog.map { entry in
      let name = isUkrainian ? entry.uk : entry.en
      return ProductsPriceModel(id: UUID().uuidString, name: name, price: entry.price)
    }

    for p in products {
      await withCheckedContinuation { continuation in
        self.saveProductsPrice(productPrice: p) { _ in
          continuation.resume()
        }
      }
    }

    let calendar = Calendar.current
    for i in 0..<max(1, days) {
      guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }

      let typeCount = (i % 3) + 1
      var rotated = types
      let shift = i % max(1, rotated.count)
      if shift > 0 {
        rotated = Array(rotated[shift...]) + Array(rotated[..<shift])
      }
      let dayTypes = Array(rotated.prefix(typeCount))

      for type in dayTypes {
        let orderId = UUID().uuidString
        let itemCount = 3 + (i % 3)  // 3..5 items per order
        var chosen = Array(products.shuffled().prefix(itemCount))
        var orderItems = [ProductOfOrderModel]()

        for (idx, base) in chosen.enumerated() {
          let qty = 1 + ((i + idx) % 4)  // 1..4 units per item
          let sum = Double(qty) * base.price
          orderItems.append(
            ProductOfOrderModel(
              id: UUID().uuidString,
              orderId: orderId,
              date: date,
              name: base.name,
              quantity: qty,
              price: base.price,
              sum: sum
            )
          )
        }

        let total = orderItems.reduce(0) { $0 + $1.sum }
        let cash = total * 0.6
        let card = total - cash

        let order = OrderModel(
          id: orderId,
          date: date,
          type: type.name,
          sum: total,
          cash: cash,
          card: card
        )

        let savedOrderId: String? = await withCheckedContinuation { continuation in
          self.saveOrder(order: order) { id in
            continuation.resume(returning: id)
          }
        }

        let targetOrderId = savedOrderId ?? orderId
        for var item in orderItems {
          item.orderId = targetOrderId
          await withCheckedContinuation { continuation in
            self.saveProduct(order: item) { _ in
              continuation.resume()
            }
          }
        }

        let costCatalog: [(uk: String, en: String, base: Double)] = [
          ("Молоко", "Milk", 30),
          ("Цукор", "Sugar", 20),
          ("Кавові зерна", "Coffee beans", 500),
          ("Оренда", "Rent", 1200),
          ("Комунальні послуги", "Utilities", 300),
          ("Електроенергія", "Electricity", 400),
          ("Вода", "Water", 60),
          ("Інтернет", "Internet", 25),
          ("Заробітна плата", "Salary", 800),
          ("Податки", "Taxes", 350),
          ("Маркетинг", "Marketing", 200),
          ("Пакування", "Packaging", 70),
          ("Прибирання", "Cleaning", 50),
          ("Обслуговування обладнання", "Equipment maintenance", 150),
        ]

        let costCount = 2 + ((i + dayTypes.count) % 3)
        for j in 0..<costCount {
          let entry = costCatalog[(i + j) % costCatalog.count]
          let name = isUkrainian ? entry.uk : entry.en
          let variance = Double(((i * 17) + (j * 11)) % 120)
          let amount = (entry.base + variance).rounded(.toNearestOrAwayFromZero)
          let cost = CostModel(
            id: UUID().uuidString,
            date: date,
            name: name,
            sum: amount
          )
          await withCheckedContinuation { continuation in
            self.saveCost(model: cost) { _ in
              continuation.resume()
            }
          }
        }
      }
    }
  }

  func transferCollectionToFIR<RealmModel, DomainModel, FIRModel>(
    collection: String, realmModelType: RealmModel.Type,
    domainModelInit: @escaping (RealmModel) -> DomainModel,
    firModelInit: @escaping (DomainModel) -> FIRModel, completion: @escaping () -> Void
  ) where RealmModel: Object, FIRModel: Encodable {

    DispatchQueue.global().async {
      let realm = try! Realm()
      let realmObjects = realm.objects(realmModelType)
      let internalGroup = DispatchGroup()

      for realmObject in realmObjects {
        internalGroup.enter()
        let domainModel = domainModelInit(realmObject)
        let firModel = firModelInit(domainModel)

        FirestoreDatabaseService.shared.create(firModel: firModel, collection: collection) {
          result in
          switch result {
          case .success(let documentId):
            self.logger.info(
              "Created document \(collection) with id - \(String(describing: documentId))")
            if collection == FirebaseCollections.orders {
              let model = domainModel as! OrderModel
              self.orderIdMap[model.id] = documentId
            }
          case .failure(let error):
            self.logger.error(
              "Failed to save document \(collection) to Firestore with error: \(error.localizedDescription)"
            )
          }
          internalGroup.leave()
        }
      }

      internalGroup.notify(queue: .global()) {
        completion()
      }
    }
  }

}
