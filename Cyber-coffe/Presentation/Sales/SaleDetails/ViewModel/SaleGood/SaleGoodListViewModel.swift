//
//  SaleGoodListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

struct SaleGood {
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
                saleGood.saleDate = date
                saleGood.saleGood = goodPrice.good
                saleGood.saleQty = 0
                saleGood.salePrice = goodPrice.price
                saleGood.saleSum = 0.0
                saleGoods.append(saleGood)
            }
        } else {
            for saleGoodsElement in saleGoodsArray {
                var saleGood = SaleGood()
                saleGood.saleDate = saleGoodsElement.saleDate
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
    
    func saveSalesGood() {
        for sale in saleGoods {
            let saleGood = SaleGoodModel()
            saleGood.saleGood = sale.saleGood
            saleGood.saleDate = sale.saleDate
            saleGood.saleQty = sale.saleQty
            saleGood.salePrice = sale.salePrice
            saleGood.saleSum = sale.saleSum
            DatabaseManager.shared.saveSalesGoodModel(model: saleGood)
        }
    }
    
    func updateSalesGood() {
        
        for saleGood in saleGoods {
            let saleGoodModel = DatabaseManager.shared.fetchSaleGood(date: saleGood.saleDate,
                                                                     good: saleGood.saleGood)
            
            DatabaseManager.shared.updateSaleGoodModel(model: saleGoodModel,
                                                       saleDate: saleGood.saleDate,
                                                       saleGood: saleGood.saleGood,
                                                       saleQty: saleGood.saleQty,
                                                       salePrice: saleGood.salePrice,
                                                       saleSum: saleGood.saleSum)
        }
        
    }
    
    static func deleteSalesGood(date: Date) {
        let salesGoods = DatabaseManager.shared.fetchSaleGood(date: date)
        for saleGood in salesGoods {
            DatabaseManager.shared.deleteSaleGoodModel(model: saleGood)
        }
    }
}
