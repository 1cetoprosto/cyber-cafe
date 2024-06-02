//
//  DatabaseManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import Foundation
import RealmSwift

class RealmDatabaseService: RealmDB {
    
    static let shared = RealmDatabaseService()
    
    // MARK: - Lifecycle
    
    private init() {}
    
    let localRealm = try! Realm()
    
    func save<T: Object>(model object: T) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        do {
            try localRealm.write {
                localRealm.add(object)
            }
        } catch {
            print(error)
        }
    }
    
    func delete<T: Object>(model object: T) {
        do {
            try localRealm.write {
                localRealm.delete(object)
            }
        } catch {
            print(error)
        }
    }
    
    func printRealmData<T: Object>(modelType: T.Type) {
        let results = localRealm.objects(modelType)
        for result in results {
            for property in result.objectSchema.properties {
                if let value = result.value(forKey: property.name) {
                    print("\(property.name): \(value)")
                }
            }
        }
    }
    
    func fetchObjectById<T: Object>(ofType: T.Type, id: String) -> T? {
        return localRealm.objects(ofType).filter("id == %@", id).first
    }

    func deleteAllData(completion: @escaping () -> Void) {
        let objectTypes: [Object.Type] = [RealmProductModel.self,
                                          RealmOrderModel.self,
                                          RealmProductsPriceModel.self,
                                          RealmTypeModel.self,
                                          RealmCostModel.self]
        
        try! localRealm.write {
            for objectType in objectTypes {
                let objects = localRealm.objects(objectType)
                localRealm.delete(objects)
            }
        }
        print("Deleted all Realm documents")
        completion()
    }
    
    // MARK: - Work With Orders Product
    
    func updateProduct(model: RealmProductModel, date: Date, name: String, quantity: Int, price: Double, sum: Double) {
        try! localRealm.write {
            model.date = date
            model.name = name
            model.quantity = quantity
            model.price = price
            model.sum = sum
        }
    }
    
    func fetchProduct() -> [RealmProductModel] {
        return Array(localRealm.objects(RealmProductModel.self).sorted(byKeyPath: "date"))
    }
    
    func fetchProduct(forDate date: Date) -> [RealmProductModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicateDate = NSPredicate(format: "date BETWEEN %@", [dateStart, dateEnd])
        
        return Array(localRealm.objects(RealmProductModel.self).filter(predicateDate).sorted(byKeyPath: "name"))
    }
    
    func fetchProduct(forDate date: Date, withName name: String) -> RealmProductModel {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        let predicate = NSPredicate(format: "date BETWEEN %@ AND name == %@", [dateStart, dateEnd], name)
        
        return localRealm.objects(RealmProductModel.self).filter(predicate).first ?? RealmProductModel()
    }
    
    func fetchProduct(withIdOrder id: String) -> [RealmProductModel] {
        let predicate = NSPredicate(format: "orderId == %@", id)
        
        return Array(localRealm.objects(RealmProductModel.self).filter(predicate).sorted(byKeyPath: "name"))
    }
    
    // MARK: - Work With Orders
    
    func updateOrders(model: RealmOrderModel, date: Date, type: String, total: Double, cashAmount: Double, cardAmount: Double) {
        try! localRealm.write {
            model.date = date
            model.type = type
            model.sum = total
            model.cash = cashAmount
            model.card = cardAmount
        }
    }

    func fetchOrders() -> [RealmOrderModel] {
        return Array(localRealm.objects(RealmOrderModel.self).sorted(byKeyPath: "date"))
    }
    
    func fetchSectionsOfOrders() -> [(date: Date, items: [RealmOrderModel])] {
        let results = localRealm.objects(RealmOrderModel.self).sorted(byKeyPath: "date",  ascending: false)
        
        let sections = results
            .map { item in
                // get start of a day
                return Calendar.current.startOfDay(for: item.date)
            }
            .reduce([]) { dates, date in
                // unique sorted array of dates
                return dates.last == date ? dates : dates + [date]
            }
            .compactMap { startDate -> (date: Date, items: [RealmOrderModel])? in
                // create the end of current day
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                // filter sorted results by a predicate matching current day
                let items = results.filter("(date >= %@) AND (date < %@)", startDate, endDate)
                var orders = [RealmOrderModel]()
                for item in items {
                    orders.append(item)
                }
                
                // return a section only if current day is non-empty
                return items.isEmpty ? nil : (date: startDate, items: orders)
            }
        return sections
    }
    
    func fetchOrder(forOrderModel ordersModel: OrderModel) -> RealmOrderModel? {
//        let predicate = NSPredicate(format: "id == %@", id)
//        
//        return Array(localRealm.objects(RealmProductModel.self).filter(predicate).sorted(byKeyPath: "name"))
//        return localRealm.object(ofType: RealmOrderModel.self, forPrimaryKey: ordersModel.id)
        return fetchObjectById(ofType: RealmOrderModel.self, id: ordersModel.id)
    }

    func fetchOrder(forId id: String) -> RealmOrderModel? {
        //return localRealm.object(ofType: RealmOrderModel.self, forPrimaryKey: id)
        return fetchObjectById(ofType: RealmOrderModel.self, id: id)
    }
    
    func fetchOrders(forDate date: Date, ofType type: String?) -> [RealmOrderModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicate = NSPredicate(format: "date BETWEEN %@ AND type == %@", [dateStart, dateEnd], type ?? "Sunday service")
        return Array(localRealm.objects(RealmOrderModel.self).filter(predicate))
    }

    // MARK: - Work With Product Price
    
    func updateProductsPrice(model: RealmProductsPriceModel, name: String, price: Double) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.name = name
            model.price = price
        }
    }

    func fetchProductsPrice() -> [RealmProductsPriceModel] {
        return Array(localRealm.objects(RealmProductsPriceModel.self).sorted(byKeyPath: "name"))
    }
    
    func fetchProductsPrice(forProductPriceModel productPriceModel: ProductsPriceModel) -> RealmProductsPriceModel? {
        //return localRealm.objects(RealmProductsPriceModel.self).filter("id == %@", productPriceModel.id).first
        //guard let model = fetchObjectById(modelType: RealmProductsPriceModel.self, id: productPriceModel.id) else { return nil}
        return fetchObjectById(ofType: RealmProductsPriceModel.self, id: productPriceModel.id)
    }
    
    // MARK: - Work With Cost
    
    func updateCost(model: RealmCostModel, date: Date, name: String, sum: Double) {
        try! localRealm.write {
            model.date = date
            model.name = name
            model.sum = sum
        }
    }

    func fetchCosts() -> [RealmCostModel] {
        return Array(localRealm.objects(RealmCostModel.self).sorted(byKeyPath: "date"))
    }
    
    func fetchCosts(forCostModel costModel: CostModel) -> RealmCostModel? {
        //return localRealm.objects(RealmCostModel.self).filter("id == %@", costModel.id).first
        return fetchObjectById(ofType: RealmCostModel.self, id: costModel.id)
    }
    
    func fetchSectionsOfCosts() -> [(date: Date, items: [RealmCostModel])] {
        let results = localRealm.objects(RealmCostModel.self).sorted(byKeyPath: "date",  ascending: false)
        
        let sections: [(date: Date, items: [RealmCostModel])] = results
            .map { item in
                // get start of a day
                return Calendar.current.startOfDay(for: item.date)
            }
            .reduce([]) { dates, date in
                // unique sorted array of dates
                return dates.last == date ? dates : dates + [date]
            }
            .compactMap { startDate -> (date: Date, items: [RealmCostModel])? in
                // create the end of current day
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                // filter sorted results by a predicate matching current day
                let items = results.filter("(date >= %@) AND (date < %@)", startDate, endDate)
                var costs = [RealmCostModel]()
                for item in items {
                    costs.append(item)
                }
                
                // return a section only if current day is non-empty
                return items.isEmpty ? nil : (date: startDate, items: costs)
            }
        return sections
    }
    
    // MARK: - Work With Type
    
    func updateType(model: RealmTypeModel, type: String) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.name = type
        }
    }

    func fetchTypes() -> [RealmTypeModel] {
        return Array(localRealm.objects(RealmTypeModel.self).sorted(byKeyPath: "name"))
    }
    
    func fetchTypes(forTypeModel typeModel: TypeModel) -> RealmTypeModel? {
        //return localRealm.objects(RealmTypeModel.self).filter("id == %@", typeModel.id).first
        return fetchObjectById(ofType: RealmTypeModel.self, id: typeModel.id)
    }
    
}
