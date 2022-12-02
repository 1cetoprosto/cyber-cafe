//
//  SaleGoodListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

struct SaleGood {
    var saleId: String = ""
    var saleDate = Date()
    var saleGood: String = ""
    var saleQty: Int = 0
    var salePrice: Double = 0.0
    var saleSum: Double = 0.0
}

class SaleGoodListViewModel: SaleGoodListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    private var saleGoods = [SaleGood]()
    
    func getSaleGoods(date: Date, completion: @escaping () -> ()) {
        let saleGoodsArray = DatabaseManager.shared.fetchSaleGood(date: date)
        
        if saleGoodsArray.isEmpty {
            let goodsPrice = DatabaseManager.shared.fetchGoodsPrice()
            
            for goodPrice in goodsPrice {
                var saleGood = SaleGood()
                //saleGood.saleId = ""
                saleGood.saleDate = date
                saleGood.saleGood = goodPrice.good
                //saleGood.saleQty = 0
                saleGood.salePrice = goodPrice.price
                //saleGood.saleSum = 0.0
                saleGoods.append(saleGood)
            }
        } else {
            for saleGoodsElement in saleGoodsArray {
                var saleGood = SaleGood()
                saleGood.saleId = saleGoodsElement.id
                saleGood.saleDate = saleGoodsElement.date
                saleGood.saleGood = saleGoodsElement.saleGood
                saleGood.saleQty = saleGoodsElement.saleQty
                saleGood.salePrice = saleGoodsElement.salePrice
                saleGood.saleSum = saleGoodsElement.saleSum
                saleGoods.append(saleGood)
            }
        }
        
        completion()
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        return saleGoods.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> SaleGoodListItemViewModelType? {
        let saleGood = saleGoods[indexPath.row]
        return SaleGoodListItemViewModel(saleGood: saleGood, for: indexPath.row)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    func setQuantity(tag: Int, quantity: Int) {
        saleGoods[tag].saleQty = quantity
        saleGoods[tag].saleSum = Double(quantity) * saleGoods[tag].salePrice
    }
    
    func getQuantity() -> Double {
        guard let atIndex = selectedIndexPath?.row else { return 0.0 }
        let saleQty = Double(saleGoods[atIndex].saleQty)
        
        return saleQty
    }
    
    func totalSum() -> String {
        var totalSum: Double = 0.0
        
        for good in saleGoods {
            totalSum += good.saleSum
        }
        
        return String(totalSum)
    }
    
    func saveSalesGood(date: Date) {
        for sale in saleGoods {
            let saleGoodModel = SaleGoodModel()
            saleGoodModel.saleGood = sale.saleGood
            saleGoodModel.date = date
            saleGoodModel.saleQty = sale.saleQty
            saleGoodModel.salePrice = sale.salePrice
            saleGoodModel.saleSum = sale.saleSum
            
            if let id = FIRFirestoreService
                .shared
                //.createSaleGood(firSaleGood: FIRSaleGood(saleGoodModel: saleGoodModel)) {
                .create(firModel: FIRSaleGoodModel(saleGoodModel: saleGoodModel), collection: "saleGood") {
                saleGoodModel.id = id
                saleGoodModel.synchronized = true
            }
            
            DatabaseManager.shared.save(model: saleGoodModel)
        }
    }
    
    func updateSalesGood(date: Date) {
        
        for saleGood in saleGoods {
            
            let saleGoodModel = DatabaseManager
                .shared
                .fetchSaleGood(date: saleGood.saleDate,
                               good: saleGood.saleGood)
            
            let saleSynchronized = FIRFirestoreService
                .shared
                .update(firModel: FIRSaleGoodModel(saleId: saleGood.saleId,
                                              saleDate: date,
                                              saleGood: saleGood.saleGood,
                                              saleQty: saleGood.saleQty,
                                              salePrice: saleGood.salePrice,
                                              saleSum: saleGood.saleSum),
                        collection: "saleGood",
                        documentId: saleGood.saleId)
//                .updateSaleGood(firSaleGood: FIRSaleGood(saleId: saleGood.saleId,
//                                                         saleDate: date,
//                                                         saleGood: saleGood.saleGood,
//                                                         saleQty: saleGood.saleQty,
//                                                         salePrice: saleGood.salePrice,
//                                                         saleSum: saleGood.saleSum))
            
            DatabaseManager
                .shared
                .updateSaleGoodModel(model: saleGoodModel,
                                     saleDate: date,
                                     saleGood: saleGood.saleGood,
                                     saleQty: saleGood.saleQty,
                                     salePrice: saleGood.salePrice,
                                     saleSum: saleGood.saleSum,
                                     saleSynchronized: saleSynchronized)
        }
        
    }
    
    static func deleteSalesGood(date: Date) {
        let salesGoods = DatabaseManager.shared.fetchSaleGood(date: date)
        for saleGood in salesGoods {
            let saleDeleted = FIRFirestoreService.shared.delete(collection: "saleGood", documentId: saleGood.id) //deleteSaleGood(documentId: saleGood.saleId)
            if saleDeleted {
                DatabaseManager.shared.delete(model: saleGood)
            } else {
                //TODO: add in table for delete later, when wiil be sinhronize
                
            }
        }
    }
}
