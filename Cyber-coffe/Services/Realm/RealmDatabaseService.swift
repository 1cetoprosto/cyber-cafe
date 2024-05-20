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
    
    func fetchSaleGood(forDate date: Date) -> [RealmSaleGoodModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicateDate = NSPredicate(format: "date BETWEEN %@", [dateStart, dateEnd])
        
        return Array(localRealm.objects(RealmSaleGoodModel.self).filter(predicateDate).sorted(byKeyPath: "saleGood"))
    }
    
    func fetchSaleGood(forDate date: Date, withName name: String) -> RealmSaleGoodModel {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        let predicate = NSPredicate(format: "date BETWEEN %@ AND saleGood == %@", [dateStart, dateEnd], name)
        
        return localRealm.objects(RealmSaleGoodModel.self).filter(predicate)[0]
    }
    
    func saveSaleGood(saleGood: RealmSaleGoodModel) {
        do {
            try localRealm.write {
                localRealm.add(saleGood)
            }
        } catch {
            print("Failed to save sale to Realm: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Work With Daily Sales Good
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
    
    func saveDailySale(dailySale: RealmDailySalesModel) {
        do {
            try localRealm.write {
                localRealm.add(dailySale)
            }
        } catch {
            print("Failed to save sale to Realm: \(error.localizedDescription)")
        }
    }
    
    func fetchDailySales(forDailySalesModel dailySalesModel: DailySalesModel) -> RealmDailySalesModel? {
        return localRealm.object(ofType: RealmDailySalesModel.self, forPrimaryKey: dailySalesModel.id)
    }

    func fetchSales(forDate date: Date, ofType type: String?) -> [RealmDailySalesModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicate = NSPredicate(format: "date BETWEEN %@ AND typeOfDonation == %@", [dateStart, dateEnd], type ?? "Sunday service")
        return Array(localRealm.objects(RealmDailySalesModel.self).filter(predicate))
    }

    // Товари та ціни
    func updateGoodsPrice(model: RealmGoodsPriceModel, name: String, price: Double) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.name = name
            model.price = price
        }
    }

    func fetchGoodsPrice() -> [RealmGoodsPriceModel] {
        return Array(localRealm.objects(RealmGoodsPriceModel.self).sorted(byKeyPath: "good"))
    }
    
    func fetchGoodsPrice(forGoodPriceModel goodPriceModel: GoodsPriceModel) -> RealmGoodsPriceModel? {
        return localRealm.object(ofType: RealmGoodsPriceModel.self, forPrimaryKey: goodPriceModel.id)
    }
    
    // Закупки
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
        return localRealm.object(ofType: RealmPurchaseModel.self, forPrimaryKey: purchaseModel.id)
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
    
    // Типи пожертвувань
    func updateIncomeType(model: RealmIncomeTypeModel, type: String) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.name = type
        }
    }

    func fetchIncomeTypes() -> [RealmIncomeTypeModel] {
        return Array(localRealm.objects(RealmIncomeTypeModel.self).sorted(byKeyPath: "type"))
    }

    func fetchIncomeTypes(forIncomeTypeModel incomeTypeModel: IncomeTypeModel) -> RealmIncomeTypeModel? {
        return localRealm.object(ofType: RealmIncomeTypeModel.self, forPrimaryKey: incomeTypeModel.id)
    }
    
    func deleteAllData() {
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
    }
}
