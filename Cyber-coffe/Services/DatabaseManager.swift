//
//  RealmManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import RealmSwift

class DatabaseManager {
    static let shared = DatabaseManager()
    
    // MARK: - Lifecycle
    private init() {}
    
    let localRealm = try! Realm()

    // MARK: - Work With Sales Good
    func saveSalesGoodModel(model: SaleGoodModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func updateSaleGoodModel(model: SaleGoodModel, saleDate: Date, saleGood: String, saleQty: Int, saleSum: Double) {
        try! localRealm.write {
            model.saleDate = saleDate
            model.saleGood = saleGood
            model.saleQty = saleQty
            model.saleSum = saleSum
        }
    }
    
    func deleteSaleGoodModel(model: SaleGoodModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    func fetchSaleGood() -> [SaleGoodModel] {
        return Array(localRealm.objects(SaleGoodModel.self))
    }
    
    // Продажи и касса
    func saveSalesModel(model: SalesModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func updateSalesModel(model: SalesModel, salesDate: Date, salesSum: Double, salesCash: Double) {
        try! localRealm.write {
            model.salesDate = salesDate
            model.salesSum = salesSum
            model.salesCash = salesCash
        }
    }

    func deleteSalesModel(model: SalesModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    func fetchSales() -> [SalesModel] {
        return Array(localRealm.objects(SalesModel.self).sorted(byKeyPath: "salesDate"))
    }

    // Товары и цены
    func saveGoodsPriceModel(model: GoodsPriceModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }

    func updateGoodsPriceModel(model: GoodsPriceModel, good: String, price: Double) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.good = good
            model.price = price
        }
    }

    func deleteGoodsPriceModel(model: GoodsPriceModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    // Закупки
    func savePurchaseModel(model: PurchaseModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }

    func updatePurchaseModel(model: PurchaseModel, purchaseDate: Date, purchaseName: String, purchaseSum: Double) {
        try! localRealm.write {
            model.purchaseDate = purchaseDate
            model.purchaseGood = purchaseName
            model.purchaseSum = purchaseSum
        }
    }

    func deletePurchaseModel(model: PurchaseModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    func fetchPurchases() -> [PurchaseModel] {
        return Array(localRealm.objects(PurchaseModel.self).sorted(byKeyPath: "purchaseDate"))
    }
}
