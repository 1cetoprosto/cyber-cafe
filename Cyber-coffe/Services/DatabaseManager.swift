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
    
    func updateSaleGoodModel(model: SaleGoodModel, saleDate: Date, saleGood: String, saleQty: Int, salePrice: Double, saleSum: Double) {
        try! localRealm.write {
            model.saleDate = saleDate
            model.saleGood = saleGood
            model.saleQty = saleQty
            model.salePrice = salePrice
            model.saleSum = saleSum
        }
    }
    
    func deleteSaleGoodModel(model: SaleGoodModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    func fetchSaleGood(date: Date) -> [SaleGoodModel] {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicateDate = NSPredicate(format: "saleDate BETWEEN %@", [dateStart, dateEnd])
        
        return Array(localRealm.objects(SaleGoodModel.self).filter(predicateDate).sorted(byKeyPath: "saleGood"))
    }
    
    func fetchSaleGood(date: Date, good: String) -> SaleGoodModel {
        let dateStart = Calendar.current.startOfDay(for: date)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        let predicate = NSPredicate(format: "saleDate BETWEEN %@ AND saleGood == %@", [dateStart, dateEnd], good)
        
        return localRealm.objects(SaleGoodModel.self).filter(predicate)[0]
    }
    
    // Продажи и касса
    func saveSalesModel(model: SalesModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }
    
    func updateSalesModel(model: SalesModel, salesDate: Date, salesTypeOfDonation: String, salesSum: Double, salesCash: Double) {
        try! localRealm.write {
            model.salesDate = salesDate
            model.salesTypeOfDonation = salesTypeOfDonation
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

    // Товари та ціни
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
    
    func fetchGoodsPrice() -> [GoodsPriceModel] {
        return Array(localRealm.objects(GoodsPriceModel.self).sorted(byKeyPath: "good"))
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
    
    // Типи пожертвувань
    func saveTypeOfDonationModel(model: TypeOfDonationModel) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            localRealm.add(model)
        }
    }

    func updateTypeOfDonationModel(model: TypeOfDonationModel, type: String) {
        print("Realm is located at:", localRealm.configuration.fileURL!)
        try! localRealm.write {
            model.type = type
        }
    }

    func deleteTypeOfDonationModel(model: TypeOfDonationModel) {
        try! localRealm.write {
            localRealm.delete(model)
        }
    }
    
    func fetchTypeOfDonation() -> [TypeOfDonationModel] {
        return Array(localRealm.objects(TypeOfDonationModel.self).sorted(byKeyPath: "type"))
    }
}
