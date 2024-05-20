//
//  SaleGoodListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.03.2022.
//

import Foundation

class SaleGoodListViewModel: SaleGoodListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    private var saleGoods = [SaleGoodModel]() 
    
    func getSaleGoods(date: Date, completion: @escaping () -> Void) {
        
        saleGoods.removeAll()
        
        DomainDatabaseService.shared.fetchSaleGood(forDate: date) { [weak self] saleGoodsArray in
            guard let self = self else { return }
            
            if saleGoodsArray.isEmpty {
                DomainDatabaseService.shared.fetchGoodsPrice { goodsPrice in
                    for goodPrice in goodsPrice {
                        let saleGood = SaleGoodModel(id: "",
                                                     date: date,
                                                     name: goodPrice.name,
                                                     quantity: 0,
                                                     price: goodPrice.price,
                                                     sum: 0)
                        self.saleGoods.append(saleGood)
                    }
                }
            } else {
                self.saleGoods = saleGoodsArray
            }
            
            completion()
        }
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
        saleGoods[tag].quantity = quantity
        saleGoods[tag].sum = Double(quantity) * saleGoods[tag].price
    }
    
    func getQuantity() -> Double {
        guard let atIndex = selectedIndexPath?.row else { return 0.0 }
        let saleQty = Double(saleGoods[atIndex].quantity)
        
        return saleQty
    }
    
    func totalSum() -> String {
        var totalSum: Double = 0.0
        
        for good in saleGoods {
            totalSum += good.sum
        }
        
        return String(totalSum)
    }
    
    func saveSalesGood(date: Date) {
        for sale in saleGoods {
            DomainDatabaseService.shared.saveSaleGood(sale: sale) { success in
                if success {
                    print("Sale saved successfully")
                } else {
                    print("Failed to save sale")
                }
            }
        }
    }
    
    func updateSalesGood(date: Date) {
        for saleGood in saleGoods {
            DomainDatabaseService.shared.updateSaleGood(model: saleGood,
                              date: date,
                              name: saleGood.name,
                              quantity: saleGood.quantity,
                              price: saleGood.price,
                              sum: saleGood.sum)
        }
    }
    
    static func deleteSalesGood(date: Date) {
        DomainDatabaseService.shared.fetchSaleGood(forDate: date) { salesGoods in
            for saleGood in salesGoods {
                DomainDatabaseService.shared.deleteSaleGood(sale: saleGood) { success in
                    if success {
                        print("Delete sale successfully")
                    } else {
                        print("Failed to delete sale")
                    }
                }
            }
        }
    }
}
