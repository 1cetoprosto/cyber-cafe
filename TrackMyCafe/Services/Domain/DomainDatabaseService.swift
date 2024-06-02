//
//  Repository.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation
import RealmSwift

class DomainDatabaseService: DomainDB {
    
    static let shared = DomainDatabaseService()
    
    // Метод для перевірки, чи включений режим онлайн
    private func isOnlineModeEnabled() -> Bool {
        return SettingsManager.shared.loadOnline()
    }
    
    // MARK: - Product Operations
    
    func updateProduct(model: ProductModel, date: Date, name: String, quantity: Int, price: Double, sum: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            var updatedModel = FIRProductModel(dataModel: model)
            updatedModel.date = date
            updatedModel.name = name
            updatedModel.quantity = quantity
            updatedModel.price = price
            updatedModel.amount = sum
            
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "orders", documentId: model.id) {
                print("Order product updated successfully in Firestore database")
            } else {
                print("Failed to update order product in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmProductModel.self, id: model.id) else { return }
            RealmDatabaseService.shared.updateProduct(model: updatedModel, date: date, name: name, quantity: quantity, price: price, sum: sum)
        }
    }
    
    // Асинхронний метод для отримання списку продаж
    func fetchProduct(forDate date: Date, completion: @escaping ([ProductModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.readOrdersOfProducts { firProducts in
                let ordersProduct = firProducts.map { ProductModel(firebaseModel: $0.1) }
                completion(ordersProduct)
            }
        } else {
            let ordersProduct = RealmDatabaseService.shared.fetchProduct(forDate: date)
                .map { ProductModel(realmModel: $0) }
            completion(ordersProduct)
        }
    }
    
    func fetchProduct(forDate date: Date, withName name: String, completion: @escaping (ProductModel?) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "orders", firModel: FIRProductModel.self) { firOrder in
                let ordersProduct = firOrder.map { ProductModel(firebaseModel: $1) }
                let filteredProduct = ordersProduct.first { $0.date == date && $0.name == name }
                completion(filteredProduct)
            }
        } else {
            let product = RealmDatabaseService.shared.fetchProduct(forDate: date, withName: name)
            completion(ProductModel(realmModel: product))
        }
    }
    
    func fetchProduct(withOrderId id: String, completion: @escaping ([ProductModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "orders", firModel: FIRProductModel.self) { firOrder in
                let ordersProduct = firOrder.map { ProductModel(firebaseModel: $1) }
                let filteredProduct = ordersProduct.filter { $0.orderId == id }
                completion(filteredProduct)
            }
        } else {
            let ordersProduct = RealmDatabaseService.shared.fetchProduct(withIdOrder: id)
                .map { ProductModel(realmModel: $0) }
            completion(ordersProduct)
        }
    }
    
    func saveProduct(order: ProductModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createOrdersOfProducts(order: FIRProductModel(dataModel: order)) { success in
                if success {
                    print("Order product saved to Firestore successfully")
                } else {
                    print("Failed to save order product to Firestore")
                }
                completion(success)
            }
        } else {
            let model = RealmProductModel(dataModel: order)
            model.id = UUID().uuidString
            RealmDatabaseService.shared.save(model: model)
            print("Order product saved to Realm successfully")
            completion(true)
        }
    }
    
    func deleteProduct(order: ProductModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "orders", documentId: order.id)
            completion(success)
        } else {
            guard let deletedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmProductModel.self, id: order.id) else { return }
            RealmDatabaseService.shared.delete(model: deletedModel)
            completion(true)
        }
    }
    
    // MARK: - Orders Operations
    
    func updateOrders(model: OrderModel, date: Date, type: String, total: Double, cashAmount: Double, cardAmount: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            var updatedModel = FIROrderModel(dataModel: model)
            updatedModel.date = date
            updatedModel.type = type
            updatedModel.sum = total
            updatedModel.cash = cashAmount
            updatedModel.card = cardAmount
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "orders", documentId: model.id) {
                print("Order product updated successfully in Firestore database")
            } else {
                print("Failed to update order product in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchOrder(forOrderModel: model) else { return }
            RealmDatabaseService.shared.updateOrders(model: updatedModel, date: date, type: type, total: total, cashAmount: cashAmount, cardAmount: cardAmount)
        }
    }
    
    func fetchOrders(completion: @escaping ([OrderModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "orders", firModel: FIROrderModel.self) { firOrders in
                let orders = firOrders.map { OrderModel(firebaseModel: $1) }
                completion(orders)
            }
        } else {
            let orders = RealmDatabaseService.shared.fetchOrders().map { OrderModel(realmModel: $0) }
            completion(orders)
        }
    }
    
    func fetchSectionsOfOrders(completion: @escaping ([(date: Date, items: [OrderModel])]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "orders", firModel: FIROrderModel.self) { firOrders in
                let calendar = Calendar.current
                let groupedOrders = Dictionary(grouping: firOrders.map { OrderModel(firebaseModel: $1) }, by: { order -> Date in
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: order.date)
                    return calendar.date(from: dateComponents)!
                })
                let sections = groupedOrders.map { (date: $0.key, items: $0.value) }
                    .sorted { $0.date < $1.date }
                completion(sections)
            }
        } else {
            let sections = RealmDatabaseService.shared.fetchSectionsOfOrders().map { (date: $0.date, items: $0.items.map { OrderModel(realmModel: $0) }) }
            completion(sections)
        }
    }
    
    //    func fetchOrders(forDate date: Date, ofType type: String?, completion: @escaping ([OrderModel]) -> Void) {
    //        let isOnline = isOnlineModeEnabled()
    //
    //        if isOnline {
    //            FirestoreDatabaseService.shared.read(collection: "orders", firModel: FIROrderModel.self) { firOrders in
    //                let orders = firOrders.map { OrderModel(firebaseModel: $1) }
    //                completion(orders.filter { $0.date == date && (type == nil || $0.type == type) })
    //            }
    //        } else {
    //            let orders = RealmDatabaseService.shared.fetchOrders(forDate: date, ofType: type).map { OrderModel(realmModel: $0) }
    //            completion(orders)
    //        }
    //    }
    
    func fetchOrders(forId id: String, completion: @escaping (OrderModel?) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "orders", firModel: FIROrderModel.self) { firorders in
                let orders = firorders.map { OrderModel(firebaseModel: $1) }
                completion(orders.filter { $0.id == id }
                    .first)
            }
        } else {
            guard let order = RealmDatabaseService.shared.fetchOrder(forId: id) else { return }
            completion(OrderModel(realmModel: order))
        }
    }
    
    func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createOrder(order: FIROrderModel(dataModel: order)) { documentId in
                if documentId != nil {
                    print("Dayily Order saved to Firestore successfully")
                } else {
                    print("Failed to save dayily order to Firestore")
                }
                completion(documentId)
            }
        } else {
            let model = RealmOrderModel(dataModel: order)
            model.id = UUID().uuidString
            RealmDatabaseService.shared.save(model: model)
            print("Orders saved to Realm successfully")
            completion(model.id)
        }
    }
    
    func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "orders", documentId: order.id)
            completion(success)
        } else {
            guard let deletedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmOrderModel.self, id: order.id) else { return }
            RealmDatabaseService.shared.delete(model: deletedModel)
            completion(true)
        }
    }
    
    // MARK: - ProductsPrice Operations
    
    func updateProductsPrice(model: ProductsPriceModel, name: String, price: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRProductsPriceModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "productsPrice", documentId: model.id) {
                print("Product price updated successfully in Firestore database")
            } else {
                print("Failed to update Product price in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchProductsPrice(forProductPriceModel: model) else { return }
            RealmDatabaseService.shared.updateProductsPrice(model: updatedModel, name: name, price: price)
        }
    }
    
    func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "productsPrice", firModel: FIRProductsPriceModel.self) { firProductsPrices in
                let productsPrices = firProductsPrices.map { ProductsPriceModel(firebaseModel: $1) }
                completion(productsPrices)
            }
        } else {
            let productsPrices = RealmDatabaseService.shared.fetchProductsPrice().map { ProductsPriceModel(realmModel: $0) }
            completion(productsPrices)
        }
    }
    
    func saveProductsPrice(productPrice: ProductsPriceModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createProduct(product: FIRProductsPriceModel(dataModel: productPrice)) { success in
                completion(success)
            }
        } else {
            RealmDatabaseService.shared.save(model: RealmProductsPriceModel(dataModel: productPrice))
            completion(true)
        }
    }
    
    func deleteProductsPrice(model: ProductsPriceModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "productsPrice", documentId: model.id)
            completion(success)
        } else {
            guard let deletedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmProductsPriceModel.self, id: model.id) else { return }
            RealmDatabaseService.shared.delete(model: deletedModel)
            completion(true)
        }
    }
    
    // MARK: - Cost Operations
    
    func updateCost(model: CostModel, date: Date, name: String, sum: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRCostModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "costs", documentId: model.id) {
                print("Cost updated successfully in Firestore database")
            } else {
                print("Failed to update Cost in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchCosts(forCostModel: model) else { return }
            RealmDatabaseService.shared.updateCost(model: updatedModel, date: date, name: name, sum: sum)
        }
    }
    
    func fetchCosts(completion: @escaping ([CostModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "costs", firModel: FIRCostModel.self) { firCosts in
                let costs = firCosts.map { CostModel(firebaseModel: $1) }
                completion(costs)
            }
        } else {
            let costs = RealmDatabaseService.shared.fetchCosts().map { CostModel(realmModel: $0) }
            completion(costs)
        }
    }
    
    func fetchSectionsOfCosts(completion: @escaping ([(date: Date, items: [CostModel])]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "costs", firModel: FIRCostModel.self) { firCosts in
                let calendar = Calendar.current
                let groupedCosts = Dictionary(grouping: firCosts.map { CostModel(firebaseModel: $1) },
                                                  by: { cost -> Date in
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: cost.date)
                    return calendar.date(from: dateComponents)!
                })
                let sections = groupedCosts.map { (date: $0.key, items: $0.value) }
                    .sorted { $0.date < $1.date }
                completion(sections)
            }
        } else {
            let sections = RealmDatabaseService.shared.fetchSectionsOfCosts().map { (date: $0.date, items: $0.items.map { CostModel(realmModel: $0) }) }
            completion(sections)
        }
    }
    
    func saveCost(cost: CostModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createCost(cost: FIRCostModel(dataModel: cost)) { success in
                if success {
                    print("Cost saved to Firestore successfully")
                } else {
                    print("Failed to save Cost to Firestore")
                }
                completion(success)
            }
        } else {
            RealmDatabaseService.shared.save(model: RealmCostModel(dataModel: cost))
            print("Cost saved to Realm successfully")
            completion(true)
        }
    }
    
    func deleteCost(cost: CostModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "costs", documentId: cost.id)
            completion(success)
        } else {
            guard let deletedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmCostModel.self, id: cost.id) else { return }
            RealmDatabaseService.shared.delete(model: deletedModel)
            completion(true)
        }
    }
    
    // MARK: - Type Operations
    
    func updateType(model: TypeModel, type: String) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRTypeModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "types", documentId: model.id) {
                print("Type updated successfully in Firestore database")
            } else {
                print("Failed to update Type in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmTypeModel.self, id: model.id) else { return }
            RealmDatabaseService.shared.updateType(model: updatedModel, type: type)
        }
    }
    
    func fetchTypes(completion: @escaping ([TypeModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "types", firModel: FIRTypeModel.self) { firTypes in
                let types = firTypes.map { TypeModel(firebaseModel: $1) }
                completion(types)
            }
        } else {
            let types = RealmDatabaseService.shared.fetchTypes().map { TypeModel(realmModel: $0) }
            completion(types)
        }
    }
    
    func saveType(type: TypeModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createType(type: FIRTypeModel(dataModel: type)) { success in
                completion(success)
            }
        } else {
            RealmDatabaseService.shared.save(model: RealmTypeModel(dataModel: type))
            completion(true)
        }
    }
    
    func deleteType(model: TypeModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "types", documentId: model.id)
            completion(success)
        } else {
            guard let deletedModel = RealmDatabaseService.shared.fetchObjectById(ofType: RealmTypeModel.self, id: model.id) else { return }
            RealmDatabaseService.shared.delete(model: deletedModel)
            completion(true)
        }
    }
    
    // MARK: - delete Operations
    
    func deleteAllData(completion: @escaping () -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.deleteAllData {
                print("All data deleted successfully from Firestore database")
                completion()
            }
        } else {
            RealmDatabaseService.shared.deleteAllData {
                print("All data deleted successfully from Realm database")
                completion()
            }
        }
    }
    
    // MARK: - general Operations
    
    func transferDataFromFIRToRealm(completion: @escaping () -> Void) {
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        RealmDatabaseService.shared.deleteAllData {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        transferCollectionToRealm(collection: "orders",
                                  firModelType: FIROrderModel.self,
                                  domainModelInit: OrderModel.init(firebaseModel:),
                                  realmModelInit: RealmOrderModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        transferCollectionToRealm(collection: "orders",
                                  firModelType: FIRProductModel.self,
                                  domainModelInit: ProductModel.init(firebaseModel:),
                                  realmModelInit: RealmProductModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        transferCollectionToRealm(collection: "costs",
                                  firModelType: FIRCostModel.self,
                                  domainModelInit: CostModel.init(firebaseModel:),
                                  realmModelInit: RealmCostModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        transferCollectionToRealm(collection: "productsPrice",
                                  firModelType: FIRProductsPriceModel.self,
                                  domainModelInit: ProductsPriceModel.init(firebaseModel:),
                                  realmModelInit: RealmProductsPriceModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        transferCollectionToRealm(collection: "types",
                                  firModelType: FIRTypeModel.self,
                                  domainModelInit: TypeModel.init(firebaseModel:),
                                  realmModelInit: RealmTypeModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            FirestoreDatabaseService.shared.deleteAllData {
                completion()
            }
        }
    }
    
    func transferCollectionToRealm<FIRModel, DomainModel, RealmModel>(collection: String, firModelType: FIRModel.Type, domainModelInit: @escaping (FIRModel) -> DomainModel, realmModelInit: @escaping (DomainModel) -> RealmModel, completion: @escaping () -> Void) where FIRModel: Codable, RealmModel: Object {
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            FirestoreDatabaseService.shared.read(collection: collection, firModel: firModelType) { firModels in
                for (_, firModel) in firModels {
                    let domainModel = domainModelInit(firModel)
                    let realmModel = realmModelInit(domainModel)
                    RealmDatabaseService.shared.save(model: realmModel)
                }
            }
            print("Saved document \(collection) with firModelType - \(firModelType)")
            completion()
        }
    }
    
    var orderIdMap: [String: String] = [:]
    func transferDataFromRealmToFIR(completion: @escaping () -> Void) {
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        FirestoreDatabaseService.shared.deleteAllData {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        
        self.transferCollectionToFIR(collection: "orders",
                                     realmModelType: RealmOrderModel.self,
                                     domainModelInit: OrderModel.init(realmModel:),
                                     firModelInit: FIROrderModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.transferCollectionToFIR(collection: "orders",
                                     realmModelType: RealmProductModel.self,
                                     domainModelInit: { realmModel in
            var domainModel = ProductModel(realmModel: realmModel)
            
            // Перевіряємо, чи існує відповідний ідентифікатор orders в словнику
            if let newOrderId = self.orderIdMap[realmModel.orderId] {
                domainModel.orderId = newOrderId // Встановлюємо правильний ідентифікатор
            }
            return domainModel
        },
                                     firModelInit: FIRProductModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.transferCollectionToFIR(collection: "costs",
                                     realmModelType: RealmCostModel.self,
                                     domainModelInit: CostModel.init(realmModel:),
                                     firModelInit: FIRCostModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.transferCollectionToFIR(collection: "productsPrice",
                                     realmModelType: RealmProductsPriceModel.self,
                                     domainModelInit: ProductsPriceModel.init(realmModel:),
                                     firModelInit: FIRProductsPriceModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.transferCollectionToFIR(collection: "types",
                                     realmModelType: RealmTypeModel.self,
                                     domainModelInit: TypeModel.init(realmModel:),
                                     firModelInit: FIRTypeModel.init(dataModel:)) {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            RealmDatabaseService.shared.deleteAllData {
                completion()
            }
        }
        
    }
    
    func transferCollectionToFIR<RealmModel, DomainModel, FIRModel>(collection: String, realmModelType: RealmModel.Type, domainModelInit: @escaping (RealmModel) -> DomainModel, firModelInit: @escaping (DomainModel) -> FIRModel, completion: @escaping () -> Void) where RealmModel: Object, FIRModel: Encodable {
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let realm = try! Realm()
            let realmObjects = realm.objects(realmModelType)
            
            for realmObject in realmObjects {
                let domainModel = domainModelInit(realmObject)
                let firModel = firModelInit(domainModel)
                let documentId = FirestoreDatabaseService.shared.create(firModel: firModel, collection: collection)
                if collection == "orders" {
                    let model = domainModel as! OrderModel
                    self.orderIdMap[model.id] = documentId
                }
                print("Created docement \(collection) with id - \(String(describing: documentId))")
            }
            completion()
        }
    }
    
}
