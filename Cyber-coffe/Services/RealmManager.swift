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
    
    func saveSalesGoodModel(model: SaleGoodModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func saveSalesModel(model: SalesModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func saveGoodsPriceModel(model: GoodsPriceModel) {
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
    
    func deleteSaleGoodModel(model: SaleGoodModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    func deleteGoodsPriceModel(model: GoodsPriceModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
}
