//
//  RealmManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 10.12.2021.
//

import RealmSwift

class RealmManager {
    static let shared = RealmManager()
    
    private init() {}
    
    let localRealm = try! Realm()
    
    //Продажи товаров
    func saveSalesGoodModel(model: SaleGoodModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func deleteSaleGoodModel(model: SaleGoodModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    //Продажи и касса
    func saveSalesModel(model: SalesModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func deleteSalesModel(model: SalesModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    //Товары и цены
    func saveGoodsPriceModel(model: GoodsPriceModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func deleteGoodsPriceModel(model: GoodsPriceModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    //Закупки
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
}
