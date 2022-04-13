//
//  SaleDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class SaleDetailsViewModel: SaleDetailsViewModelType {

    private var sale: SalesModel
    
    //private var sales: [SaleGoodModel]?
    var newModel: Bool
    
    var date: Date { return sale.salesDate}
    var moneyLabel: String { return "Donation:" }
    var moneyTextfield: String { return "Money2:" }
    var saleLabel: String { return "Money1:" }
    var salesCash: Double { return sale.salesCash }
    var salesSum: Double { return sale.salesSum }
    
    init(sale: SalesModel, newModel: Bool = false) {
        self.sale = sale
        self.newModel = newModel
    }
    
    func saveSales(date: Date, salesCash: String?, salesSum: String?) {
        
//        let salesSum = Double(salesSum ?? "0") ?? 0
//        let salesCash = Double(salesCash ?? "0") ?? 0
//
//        let salesModel = SalesModel()
//        salesModel.salesDate = date
//        salesModel.salesSum = salesSum
//        salesModel.salesCash = salesCash
        sale = SalesModel()
        sale.salesDate = date
        sale.salesSum = Double(salesSum ?? "0") ?? 0
        sale.salesCash = Double(salesCash ?? "0") ?? 0
        
        DatabaseManager.shared.saveSalesModel(model: sale)
    }
    
    func updateSales(date: Date, salesCash: String?, salesSum: String?) {
        let salesSum = Double(salesSum ?? "0") ?? 0
        let salesCash = Double(salesCash ?? "0") ?? 0
        DatabaseManager.shared.updateSalesModel(model: sale, salesDate: date, salesSum: salesSum, salesCash: salesCash)
    }
    
}
