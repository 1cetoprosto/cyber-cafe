//
//  Repository.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

class DomainDatabaseService: DomainDB {
    static let shared = DomainDatabaseService()
    
    // Метод для перевірки, чи включений режим онлайн
    private func isOnlineModeEnabled() -> Bool {
        return SettingsManager.shared.loadOnline()
    }
    
    // MARK: - SaleGood Operations
    
    func updateSaleGood(model: SaleGoodModel, date: Date, name: String, quantity: Int, price: Double, sum: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRSaleGoodModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "saleGood", documentId: model.id) {
                print("Sale good updated successfully in Firestore database")
            } else {
                print("Failed to update sale good in Firestore database")
            }
        } else {
            let updatedModel = RealmDatabaseService.shared.fetchSaleGood(forDate: date, withName: name)
                RealmDatabaseService.shared.updateSaleGood(model: updatedModel, date: date, name: name, quantity: quantity, price: price, sum: sum)
        }
    }
    
    // Асинхронний метод для отримання списку продаж
    func fetchSaleGood(forDate date: Date, completion: @escaping ([SaleGoodModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.readSales { firSaleGoods in
                let salesGood = firSaleGoods.map { SaleGoodModel(firebaseModel: $0.1) }
                completion(salesGood)
            }
        } else {
            let salesGood = RealmDatabaseService.shared.fetchSaleGood(forDate: date)
                .map { SaleGoodModel(realmModel: $0) }
            completion(salesGood)
        }
    }
    
    func fetchSaleGood(forDate date: Date, withName name: String, completion: @escaping (SaleGoodModel?) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "sales", firModel: FIRSaleGoodModel.self) { firSalesGood in
                let salesGood = firSalesGood.map { SaleGoodModel(firebaseModel: $1) }
                let filteredSaleGood = salesGood.first { $0.date == date && $0.name == name }
                completion(filteredSaleGood)
            }
        } else {
            let saleGood = RealmDatabaseService.shared.fetchSaleGood(forDate: date, withName: name)
            completion(SaleGoodModel(realmModel: saleGood))
        }
    }
    
    func saveSaleGood(sale: SaleGoodModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createSale(sale: FIRSaleGoodModel(dataModel: sale)) { success in
                if success {
                    print("Sale saved to Firestore successfully")
                } else {
                    print("Failed to save sale to Firestore")
                }
                completion(success)
            }
        } else {
            RealmDatabaseService.shared.saveSaleGood(saleGood: RealmSaleGoodModel(dataModel: sale))
            print("Sale saved to Realm successfully")
            completion(true)
        }
    }
    
    func deleteSaleGood(sale: SaleGoodModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "saleGood", documentId: sale.id)
            completion(success)
        } else {
            RealmDatabaseService.shared.delete(model: RealmSaleGoodModel(dataModel: sale))
            completion(true)
        }
    }
    
    // MARK: - Sales Operations
    
    func updateSales(model: DailySalesModel, date: Date, incomeType: String, total: Double, cashAmount: Double, cardAmount: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRDailySalesModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "sales", documentId: model.id) {
                print("Sale good updated successfully in Firestore database")
            } else {
                print("Failed to update sale good in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchDailySales(forDailySalesModel: model) else { return }
            RealmDatabaseService.shared.updateSales(model: updatedModel, date: date, incomeType: incomeType, total: total, cashAmount: cashAmount, cardAmount: cardAmount)
        }
    }
    
    func fetchSales(completion: @escaping ([DailySalesModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "sales", firModel: FIRDailySalesModel.self) { firSales in
                let sales = firSales.map { DailySalesModel(firebaseModel: $1) }
                completion(sales)
            }
        } else {
            let sales = RealmDatabaseService.shared.fetchSales().map { DailySalesModel(realmModel: $0) }
            completion(sales)
        }
    }
    
    func fetchSectionsOfSales(completion: @escaping ([(date: Date, items: [DailySalesModel])]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "sales", firModel: FIRDailySalesModel.self) { firSales in
                let groupedSales = Dictionary(grouping: firSales.map { DailySalesModel(firebaseModel: $1) }, by: { $0.date })
                let sections = groupedSales.map { (date: $0.key, items: $0.value) }
                completion(sections)
            }
        } else {
            let sections = RealmDatabaseService.shared.fetchSectionsOfSales().map { (date: $0.date, items: $0.items.map { DailySalesModel(realmModel: $0) }) }
            completion(sections)
        }
    }
    
    func fetchSales(forDate date: Date, ofType type: String?, completion: @escaping ([DailySalesModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "sales", firModel: FIRDailySalesModel.self) { firSales in
                let sales = firSales.map { DailySalesModel(firebaseModel: $1) }
                completion(sales.filter { $0.date == date && (type == nil || $0.incomeType == type) })
            }
        } else {
            let sales = RealmDatabaseService.shared.fetchSales(forDate: date, ofType: type).map { DailySalesModel(realmModel: $0) }
            completion(sales)
        }
    }
    
    func saveDailySale(sale: DailySalesModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.createDailySale(dailySale: FIRDailySalesModel(dataModel: sale)) { success in
                if success {
                    print("Sale saved to Firestore successfully")
                } else {
                    print("Failed to save sale to Firestore")
                }
                completion(success)
            }
        } else {
            RealmDatabaseService.shared.saveDailySale(dailySale: RealmDailySalesModel(dataModel: sale))
            print("Sale saved to Realm successfully")
            completion(true)
        }
    }
    
    func deleteDailySale(sale: DailySalesModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "sales", documentId: sale.id)
            completion(success)
        } else {
            RealmDatabaseService.shared.delete(model: RealmDailySalesModel(dataModel: sale))
            completion(true)
        }
    }
    
    // MARK: - GoodsPrice Operations
    
    func updateGoodsPrice(model: GoodsPriceModel, name: String, price: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRGoodsPriceModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "goodsPrice", documentId: model.id) {
                print("Good price updated successfully in Firestore database")
            } else {
                print("Failed to update Good price in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchGoodsPrice(forGoodPriceModel: model) else { return }
            RealmDatabaseService.shared.updateGoodsPrice(model: updatedModel, name: name, price: price)
        }
    }
    
    func fetchGoodsPrice(completion: @escaping ([GoodsPriceModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "goodsPrice", firModel: FIRGoodsPriceModel.self) { firGoodsPrices in
                let goodsPrices = firGoodsPrices.map { GoodsPriceModel(firebaseModel: $1) }
                completion(goodsPrices)
            }
        } else {
            let goodsPrices = RealmDatabaseService.shared.fetchGoodsPrice().map { GoodsPriceModel(realmModel: $0) }
            completion(goodsPrices)
        }
    }
    
    // MARK: - Purchase Operations
    
    func updatePurchase(model: PurchaseModel, date: Date, name: String, sum: Double) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRPurchaseModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "purchases", documentId: model.id) {
                print("Purchase updated successfully in Firestore database")
            } else {
                print("Failed to update Purchase in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchPurchases(forPurchaseModel: model) else { return }
            RealmDatabaseService.shared.updatePurchase(model: updatedModel, date: date, name: name, sum: sum)
        }
    }
    
    func fetchPurchases(completion: @escaping ([PurchaseModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "purchases", firModel: FIRPurchaseModel.self) { firPurchases in
                let purchases = firPurchases.map { PurchaseModel(firebaseModel: $1) }
                completion(purchases)
            }
        } else {
            let purchases = RealmDatabaseService.shared.fetchPurchases().map { PurchaseModel(realmModel: $0) }
            completion(purchases)
        }
    }

    func fetchSectionsOfPurchases(completion: @escaping ([(date: Date, items: [PurchaseModel])]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "purchases", firModel: FIRPurchaseModel.self) { firPurchases in
                let groupedPurchases = Dictionary(grouping: firPurchases.map { PurchaseModel(firebaseModel: $1) }, by: { $0.date })
                let sections = groupedPurchases.map { (date: $0.key, items: $0.value) }
                completion(sections)
            }
        } else {
            let sections = RealmDatabaseService.shared.fetchSectionsOfPurchases().map { (date: $0.date, items: $0.items.map { PurchaseModel(realmModel: $0) }) }
            completion(sections)
        }
    }
    
    func deletePurchase(purchase: PurchaseModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "purchases", documentId: purchase.id)
            completion(success)
        } else {
            RealmDatabaseService.shared.delete(model: RealmPurchaseModel(dataModel: purchase))
            completion(true)
        }
    }
    
    // MARK: - IncomeType Operations
    
    func updateIncomeType(model: IncomeTypeModel, type: String) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let updatedModel = FIRIncomeTypeModel(dataModel: model)
            if FirestoreDatabaseService.shared.update(firModel: updatedModel, collection: "incomeTypes", documentId: model.id) {
                print("IncomeType updated successfully in Firestore database")
            } else {
                print("Failed to update IncomeType in Firestore database")
            }
        } else {
            guard let updatedModel = RealmDatabaseService.shared.fetchIncomeTypes(forIncomeTypeModel: model) else { return }
            RealmDatabaseService.shared.updateIncomeType(model: updatedModel, type: type)
        }
    }
    
    func fetchIncomeTypes(completion: @escaping ([IncomeTypeModel]) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            FirestoreDatabaseService.shared.read(collection: "incomeTypes", firModel: FIRIncomeTypeModel.self) { firIncomeTypes in
                let incomeTypes = firIncomeTypes.map { IncomeTypeModel(firebaseModel: $1) }
                completion(incomeTypes)
            }
        } else {
            let incomeTypes = RealmDatabaseService.shared.fetchIncomeTypes().map { IncomeTypeModel(realmModel: $0) }
            completion(incomeTypes)
        }
    }
 
    func deleteIncomeType(model: IncomeTypeModel, completion: @escaping (Bool) -> Void) {
        let isOnline = isOnlineModeEnabled()
        
        if isOnline {
            let success = FirestoreDatabaseService.shared.delete(collection: "incomeTypes", documentId: model.id)
            completion(success)
        } else {
            RealmDatabaseService.shared.delete(model: RealmIncomeTypeModel(dataModel: model))
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
            RealmDatabaseService.shared.deleteAllData()
            print("All data deleted successfully from Realm database")
            completion()
        }
    }
}
