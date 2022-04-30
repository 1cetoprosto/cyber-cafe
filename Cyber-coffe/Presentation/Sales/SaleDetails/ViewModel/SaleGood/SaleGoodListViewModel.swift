//
//  SaleGoodListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

class SaleGoodListViewModel: SaleGoodListViewModelType {

    private var selectedIndexPath: IndexPath?
    private var saleGoods: [SaleGoodModel]?
    
    func getSaleGoods(date: Date, completion: @escaping () -> ()) {
        saleGoods = DatabaseManager.shared.fetchSaleGood(date: date)
        guard var saleGoodsArray = saleGoods else { return }

        if saleGoodsArray.isEmpty {
            let goodsPrice = DatabaseManager.shared.fetchGoodsPrice()
            
            for goodPrice in goodsPrice {
                let saleGoodModel = SaleGoodModel()
                saleGoodModel.saleDate = date
                saleGoodModel.saleGood = goodPrice.good
                saleGoodModel.saleQty = 0
                saleGoodModel.salePrice = goodPrice.price
                saleGoodModel.saleSum = 0.0
                DatabaseManager.shared.saveSalesGoodModel(model: saleGoodModel)
                saleGoodsArray.append(saleGoodModel)
            }
            self.saleGoods = saleGoodsArray
        }
        completion()
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        return saleGoods?.count ?? 0
    }
    
    func cellViewModel(for indexPath: IndexPath) -> SaleGoodListItemViewModelType? {
        guard let saleGoodsArray = self.saleGoods else { return nil }
        let saleGood = saleGoodsArray[indexPath.row]
        return SaleGoodListItemViewModel(saleGood: saleGood, for: indexPath.row)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
    
    func setQuantity(tag: Int, quantity: Int) {
        guard let saleGoodsArray = self.saleGoods else { return }
        let saleGoodModel = saleGoodsArray[tag]
        let saleSum = Double(quantity) * saleGoodModel.salePrice
        DatabaseManager.shared.updateSaleGoodModel(model: saleGoodModel,
                                                   saleDate: saleGoodModel.saleDate,
                                                   saleGood: saleGoodModel.saleGood,
                                                   saleQty: quantity,
                                                   saleSum: saleSum)
    }
    
    func getQuantity() -> Double {
        guard let saleGoodsArray = self.saleGoods else { return 0.0 }
        guard let atIndex = selectedIndexPath?.row else { return 0.0 }
        let saleQty = Double(saleGoodsArray[atIndex].saleQty)
        
        return saleQty
    }
    
    func totalSum() -> String {
        var totalSum: Double = 0.0
        
        guard let saleGoodsArray = self.saleGoods else { return "" }
        
        for good in saleGoodsArray {
            totalSum += good.saleSum
        }
        
        return String(totalSum)
    }
    
    func saveSalesGood() {
        guard let saleGoodsArray = self.saleGoods else { return }
        for sale in saleGoodsArray {
            let saleGood = SaleGoodModel()
            saleGood.saleGood = sale.saleGood
            saleGood.saleDate = sale.saleDate
            saleGood.saleQty = sale.saleQty
            saleGood.salePrice = sale.salePrice
            saleGood.saleSum = sale.saleSum
            DatabaseManager.shared.saveSalesGoodModel(model: saleGood)
        }
    }
    
    static func deleteSalesGood(date: Date) {
        let salesGoods = DatabaseManager.shared.fetchSaleGood(date: date)
        for saleGood in salesGoods {
            DatabaseManager.shared.deleteSaleGoodModel(model: saleGood)
        }
    }
}
