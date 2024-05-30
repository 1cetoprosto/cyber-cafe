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
        let objectTypes: [Object.Type] = [RealmSaleGoodModel.self,
                                          RealmDailySalesModel.self,
                                          RealmGoodsPriceModel.self,
                                          RealmIncomeTypeModel.self,
                                          RealmPurchaseModel.self]
        
        try! localRealm.write {
            for objectType in objectTypes {
                let objects = localRealm.objects(objectType)
                localRealm.delete(objects)
            }
        }
        print("Deleted all Realm documents")
        completion()
    }
    
    // MARK: - Work With Sales Good
    
    func updateSaleGood(model: RealmSaleGoodModel, date: Date, name: String, quantity: Int, price: Double, sum: Double) {
        try! localRealm.write {
            model.date = date
            model.name = name
            model.quantity = quantity
            model.price = price
            model.sum = sum
        }
    }
    
    func fetchSaleGood() -> [RealmSaleGoodModel] {
        return Array(localRealm.objects(RealmSaleGoodModel.self).sorted(byKeyPath: "date"))
    }
    
    func fetchSaleGood(forDate date: Date) -> [RealmSaleGoodModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicateDate = NSPredicate(format: "date BETWEEN %@", [dateStart, dateEnd])
        
        return Array(localRealm.objects(RealmSaleGoodModel.self).filter(predicateDate).sorted(byKeyPath: "name"))
    }
    
    func fetchSaleGood(forDate date: Date, withName name: String) -> RealmSaleGoodModel {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        let predicate = NSPredicate(format: "date BETWEEN %@ AND name == %@", [dateStart, dateEnd], name)
        
        return localRealm.objects(RealmSaleGoodModel.self).filter(predicate).first ?? RealmSaleGoodModel()
    }
    
    func fetchSaleGood(withIdDailySale id: String) -> [RealmSaleGoodModel] {
        let predicate = NSPredicate(format: "dailySalesId == %@", id)
        
        return Array(localRealm.objects(RealmSaleGoodModel.self).filter(predicate).sorted(byKeyPath: "name"))
    }
    
    // MARK: - Work With Daily Sales
    
    func updateSales(model: RealmDailySalesModel, date: Date, incomeType: String, total: Double, cashAmount: Double, cardAmount: Double) {
        try! localRealm.write {
            model.date = date
            model.incomeType = incomeType
            model.sum = total
            model.cash = cashAmount
            model.card = cardAmount
        }
    }

    func fetchSales() -> [RealmDailySalesModel] {
        return Array(localRealm.objects(RealmDailySalesModel.self).sorted(byKeyPath: "date"))
    }
    
    func fetchSectionsOfSales() -> [(date: Date, items: [RealmDailySalesModel])] {
        let results = localRealm.objects(RealmDailySalesModel.self).sorted(byKeyPath: "date",  ascending: false)
        
        let sections = results
            .map { item in
                // get start of a day
                return Calendar.current.startOfDay(for: item.date)
            }
            .reduce([]) { dates, date in
                // unique sorted array of dates
                return dates.last == date ? dates : dates + [date]
            }
            .compactMap { startDate -> (date: Date, items: [RealmDailySalesModel])? in
                // create the end of current day
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                // filter sorted results by a predicate matching current day
                let items = results.filter("(date >= %@) AND (date < %@)", startDate, endDate)
                var sales = [RealmDailySalesModel]()
                for item in items {
                    sales.append(item)
                }
                
                // return a section only if current day is non-empty
                return items.isEmpty ? nil : (date: startDate, items: sales)
            }
        return sections
    }
    
    func fetchDailySales(forDailySalesModel dailySalesModel: DailySalesModel) -> RealmDailySalesModel? {
//        let predicate = NSPredicate(format: "id == %@", id)
//        
//        return Array(localRealm.objects(RealmSaleGoodModel.self).filter(predicate).sorted(byKeyPath: "name"))
//        return localRealm.object(ofType: RealmDailySalesModel.self, forPrimaryKey: dailySalesModel.id)
        return fetchObjectById(ofType: RealmDailySalesModel.self, id: dailySalesModel.id)
    }

    func fetchDailySales(forId id: String) -> RealmDailySalesModel? {
        //return localRealm.object(ofType: RealmDailySalesModel.self, forPrimaryKey: id)
        return fetchObjectById(ofType: RealmDailySalesModel.self, id: id)
    }
    
    func fetchSales(forDate date: Date, ofType type: String?) -> [RealmDailySalesModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicate = NSPredicate(format: "date BETWEEN %@ AND incomeType == %@", [dateStart, dateEnd], type ?? "Sunday service")
        return Array(localRealm.objects(RealmDailySalesModel.self).filter(predicate))
    }

    // MARK: - Work With Good Price
    
    func updateGoodsPrice(model: RealmGoodsPriceModel, name: String, price: Double) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.name = name
            model.price = price
        }
    }

    func fetchGoodsPrice() -> [RealmGoodsPriceModel] {
        return Array(localRealm.objects(RealmGoodsPriceModel.self).sorted(byKeyPath: "name"))
    }
    
    func fetchGoodsPrice(forGoodPriceModel goodPriceModel: GoodsPriceModel) -> RealmGoodsPriceModel? {
        //return localRealm.objects(RealmGoodsPriceModel.self).filter("id == %@", goodPriceModel.id).first
        //guard let model = fetchObjectById(modelType: RealmGoodsPriceModel.self, id: goodPriceModel.id) else { return nil}
        return fetchObjectById(ofType: RealmGoodsPriceModel.self, id: goodPriceModel.id)
    }
    
    // MARK: - Work With Purchase
    
    func updatePurchase(model: RealmPurchaseModel, date: Date, name: String, sum: Double) {
        try! localRealm.write {
            model.date = date
            model.name = name
            model.sum = sum
        }
    }

    func fetchPurchases() -> [RealmPurchaseModel] {
        return Array(localRealm.objects(RealmPurchaseModel.self).sorted(byKeyPath: "date"))
    }
    
    func fetchPurchases(forPurchaseModel purchaseModel: PurchaseModel) -> RealmPurchaseModel? {
        //return localRealm.objects(RealmPurchaseModel.self).filter("id == %@", purchaseModel.id).first
        return fetchObjectById(ofType: RealmPurchaseModel.self, id: purchaseModel.id)
    }
    
    func fetchSectionsOfPurchases() -> [(date: Date, items: [RealmPurchaseModel])] {
        let results = localRealm.objects(RealmPurchaseModel.self).sorted(byKeyPath: "date",  ascending: false)
        
        let sections: [(date: Date, items: [RealmPurchaseModel])] = results
            .map { item in
                // get start of a day
                return Calendar.current.startOfDay(for: item.date)
            }
            .reduce([]) { dates, date in
                // unique sorted array of dates
                return dates.last == date ? dates : dates + [date]
            }
            .compactMap { startDate -> (date: Date, items: [RealmPurchaseModel])? in
                // create the end of current day
                let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                // filter sorted results by a predicate matching current day
                let items = results.filter("(date >= %@) AND (date < %@)", startDate, endDate)
                var purchases = [RealmPurchaseModel]()
                for item in items {
                    purchases.append(item)
                }
                
                // return a section only if current day is non-empty
                return items.isEmpty ? nil : (date: startDate, items: purchases)
            }
        return sections
    }
    
    // MARK: - Work With IncomeType
    
    func updateIncomeType(model: RealmIncomeTypeModel, type: String) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.name = type
        }
    }

    func fetchIncomeTypes() -> [RealmIncomeTypeModel] {
        return Array(localRealm.objects(RealmIncomeTypeModel.self).sorted(byKeyPath: "name"))
    }
    
    func fetchIncomeTypes(forIncomeTypeModel incomeTypeModel: IncomeTypeModel) -> RealmIncomeTypeModel? {
        //return localRealm.objects(RealmIncomeTypeModel.self).filter("id == %@", incomeTypeModel.id).first
        return fetchObjectById(ofType: RealmIncomeTypeModel.self, id: incomeTypeModel.id)
    }
    
}
