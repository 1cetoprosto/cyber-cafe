//
//  DatabaseManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import Foundation
import RealmSwift
import os.log

class RealmDatabaseService: RealmDB {

  static let shared = RealmDatabaseService()
  private(set) var localRealm: Realm!

  // MARK: - Lifecycle

  private init() {
    var config = Realm.Configuration()
    config.schemaVersion = 2  // Поточна версія схеми
    config.migrationBlock = { migration, oldSchemaVersion in
      if oldSchemaVersion < 1 {
        // Міграція з версії 0 до 1 (якщо є)
        // Наприклад:
        // migration.enumerateObjects(ofType: YourObjectClass.className()) { oldObject, newObject in
        //     newObject!["newProperty"] = "defaultValue"
        // }
      }
      if oldSchemaVersion < 2 {
        // Міграція з версії 1 до 2 (навіть якщо порожня)
        // Наприклад:
        // migration.enumerateObjects(ofType: AnotherObjectClass.className()) { oldObject, newObject in
        //     newObject!["anotherNewProperty"] = 0
        // }
      }
    }

    do {
      localRealm = try Realm(configuration: config)
    } catch let error as NSError {
      if error.code == 10 {  // Код помилки "Invalid database"
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
        let realmURLs = [
          realmURL,
          realmURL.appendingPathExtension("lock"),
          realmURL.appendingPathExtension("note"),
          realmURL.appendingPathExtension("management"),
        ]
        for URL in realmURLs {
          do {
            try FileManager.default.removeItem(at: URL)
            logger.log("Deleted the old Realm database at the address: \(URL)")
          } catch {
            logger.log("Error when deleting the Realm file: \(error)")
          }
        }
        do {
          localRealm = try Realm(configuration: config)
          logger.log("A new Realm database has been created.")
        } catch {
          fatalError("Failed to initialize Realm after deleting old database: \(error)")
        }
      } else {
        fatalError("Failed to initialize Realm: \(error)")
      }
    }
  }

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!, category: "RealmDatabaseService")

  //    private let localRealm: Realm = {
  //        do {
  //            return try Realm()
  //        } catch {
  //            fatalError("Failed to initialize Realm: \(error)")
  //        }
  //    }()

  // MARK: - CRUD Operations

  func save<T: Object>(model object: T) {
    executeWrite {
      localRealm.add(object)
      logger.log("Saved object of type \(T.self)")
    }
  }

  func delete<T: Object>(model object: T) {
    executeWrite {
      localRealm.delete(object)
      logger.log("Deleted object of type \(T.self)")
    }
  }

  func fetchAll<T: Object>(modelType: T.Type) -> [T] {
    logger.log("Fetched all objects of type \(T.self)")
    return Array(localRealm.objects(modelType))
  }

  func fetchObjectById<T: Object>(ofType: T.Type, id: String) -> T? {
    logger.log("Fetched object of type \(T.self) with id: \(id, privacy: .public)")
    return localRealm.objects(ofType).filter("id == %@", id).first
  }

  func deleteAllData(completion: @escaping (Bool) -> Void) {
    executeWrite {
      let objectTypes: [Object.Type] = [
        RealmProductModel.self,
        RealmOrderModel.self,
        RealmProductsPriceModel.self,
        RealmTypeModel.self,
        RealmCostModel.self,
      ]

      for objectType in objectTypes {
        let objects = localRealm.objects(objectType)
        localRealm.delete(objects)
        logger.log("Deleted all objects of type \(objectType)")
      }
    }
    logger.log("Deleted all Realm documents")
    completion(true)
  }

  // MARK: - Utility Methods

  private func executeWrite(_ block: () -> Void) {
    do {
      try localRealm.write {
        block()
      }
    } catch {
      logger.error("Realm write error: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func createDateRange(for date: Date) -> (start: Date, end: Date) {
    let start = Calendar.current.startOfDay(for: date)
    let end = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start)!
    return (start, end)
  }

  // MARK: - Work with Order Products

  func updateProduct(
    model: RealmProductModel, date: Date, name: String, quantity: Int, price: Double, sum: Double
  ) {
    executeWrite {
      model.date = date
      model.name = name
      model.quantity = quantity
      model.price = price
      model.sum = sum
      logger.log("Updated product with id: \(model.id, privacy: .public)")
    }
  }

  func fetchProducts() -> [RealmProductModel] {
    logger.log("Fetched all products")
    return Array(localRealm.objects(RealmProductModel.self).sorted(byKeyPath: "date"))
  }

  func fetchProducts(forDate date: Date) -> [RealmProductModel] {
    let (start, end) = createDateRange(for: date)
    logger.log("Fetched products for date \(date, privacy: .public)")
    return Array(
      localRealm.objects(RealmProductModel.self)
        .filter("date BETWEEN %@", [start, end])
        .sorted(byKeyPath: "name"))
  }

  func fetchProduct(forDate date: Date, withName name: String) -> RealmProductModel? {
    let (start, end) = createDateRange(for: date)
    logger.log(
      "Fetched product with name \(name, privacy: .public) for date \(date, privacy: .public)")
    return localRealm.objects(RealmProductModel.self)
      .filter("date BETWEEN %@ AND name == %@", [start, end], name)
      .first
  }

  func fetchProducts(withOrderId id: String) -> [RealmProductModel] {
    logger.log("Fetched products for order with id: \(id, privacy: .public)")
    return Array(
      localRealm.objects(RealmProductModel.self)
        .filter("orderId == %@", id)
        .sorted(byKeyPath: "name"))
  }

  // MARK: - Work with Orders

  func updateOrder(
    model: RealmOrderModel, date: Date, type: String, total: Double, cashAmount: Double,
    cardAmount: Double
  ) {
    executeWrite {
      model.date = date
      model.type = type
      model.sum = total
      model.cash = cashAmount
      model.card = cardAmount
      logger.log("Updated order with id: \(model.id, privacy: .public)")
    }
  }

  func fetchOrders() -> [RealmOrderModel] {
    logger.log("Fetched all orders")
    return Array(localRealm.objects(RealmOrderModel.self).sorted(byKeyPath: "date"))
  }

  func fetchOrderSections() -> [(date: Date, items: [RealmOrderModel])] {
    logger.log("Fetched order sections")
    return fetchSections(ofType: RealmOrderModel.self, sortedByKeyPath: "date")
  }

  func fetchOrder(byId id: String) -> RealmOrderModel? {
    logger.log("Fetched order with id: \(id, privacy: .public)")
    return fetchObjectById(ofType: RealmOrderModel.self, id: id)
  }

  func fetchOrders(forDate date: Date, ofType type: String? = nil) -> [RealmOrderModel] {
    let (start, end) = createDateRange(for: date)
    let predicate: NSPredicate
    if let type = type {
      predicate = NSPredicate(format: "date BETWEEN %@ AND type == %@", [start, end], type)
      logger.log(
        "Fetched orders for date \(date, privacy: .public) and type \(type, privacy: .public)")
    } else {
      predicate = NSPredicate(format: "date BETWEEN %@", [start, end])
      logger.log("Fetched orders for date \(date, privacy: .public)")
    }
    return Array(localRealm.objects(RealmOrderModel.self).filter(predicate))
  }

  // MARK: - Work with Product Prices

  func updateProductPrice(model: RealmProductsPriceModel, name: String, price: Double) {
    executeWrite {
      model.name = name
      model.price = price
      logger.log("Updated product price with id: \(model.id, privacy: .public)")
    }
  }

  func fetchProductPrices() -> [RealmProductsPriceModel] {
    logger.log("Fetched all product prices")
    return Array(localRealm.objects(RealmProductsPriceModel.self).sorted(byKeyPath: "name"))
  }

  func fetchProductPrice(byId id: String) -> RealmProductsPriceModel? {
    logger.log("Fetched product price with id: \(id, privacy: .public)")
    return fetchObjectById(ofType: RealmProductsPriceModel.self, id: id)
  }

  // MARK: - Work with Costs

  func updateCost(model: RealmCostModel, date: Date, name: String, sum: Double) {
    executeWrite {
      model.date = date
      model.name = name
      model.sum = sum
      logger.log("Updated cost with id: \(model.id, privacy: .public)")
    }
  }

  func fetchCosts() -> [RealmCostModel] {
    logger.log("Fetched all costs")
    return Array(localRealm.objects(RealmCostModel.self).sorted(byKeyPath: "date"))
  }

  func fetchCost(byId id: String) -> RealmCostModel? {
    logger.log("Fetched cost with id: \(id, privacy: .public)")
    return fetchObjectById(ofType: RealmCostModel.self, id: id)
  }

  func fetchCostSections() -> [(date: Date, items: [RealmCostModel])] {
    logger.log("Fetched cost sections")
    return fetchSections(ofType: RealmCostModel.self, sortedByKeyPath: "date")
  }

  // MARK: - Work with Types

  func updateType(model: RealmTypeModel, type: String) {
    executeWrite {
      model.name = type
      logger.log("Updated type with id: \(model.id, privacy: .public)")
    }
  }

  func fetchTypes() -> [RealmTypeModel] {
    logger.log("Fetched all types")
    return Array(localRealm.objects(RealmTypeModel.self).sorted(byKeyPath: "name"))
  }

  func fetchType(byId id: String) -> RealmTypeModel? {
    logger.log("Fetched type with id: \(id, privacy: .public)")
    return fetchObjectById(ofType: RealmTypeModel.self, id: id)
  }

  // MARK: - Generic Methods

  private func fetchSections<T: Object & DateContainable>(
    ofType type: T.Type, sortedByKeyPath keyPathString: String
  ) -> [(date: Date, items: [T])] {
    let results = localRealm.objects(type).sorted(byKeyPath: keyPathString, ascending: false)

    // Створюємо масив дат
    let dates = results.map { item -> Date in
      let dateValue = item.value(forKey: keyPathString) as? Date
      return dateValue.map { Calendar.current.startOfDay(for: $0) } ?? Date()
    }

    // Видаляємо повторювані дати
    let uniqueDates = Array(Set(dates)).sorted(by: >)

    // Створюємо масив секцій
    var sections: [(date: Date, items: [T])] = []
    for date in uniqueDates {
      let endDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
      let predicate = NSPredicate(
        format: "(%K >= %@) AND (%K < %@)", keyPathString, date as CVarArg, keyPathString,
        endDate as CVarArg)
      let items = results.filter(predicate)
      if !items.isEmpty {
        sections.append((date: date, items: Array(items)))
      }
    }

    logger.log("Fetched sections for type \(type)")
    return sections
  }

}
