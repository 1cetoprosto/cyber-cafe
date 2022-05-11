//
//  SaleDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class SaleDetailsViewModel: SaleDetailsViewModelType {

    private var sale: SalesModel
    private var types: [TypeOfDonationModel]? {
        let typesArray = DatabaseManager.shared.fetchTypeOfDonation()
        if typesArray.isEmpty {
            return nil
        }
        return typesArray
    }
    private var selectedRow: Int?
    var newModel: Bool
    
    var date: Date { return sale.salesDate}
    var moneyLabel: String { return "Donation:" }
    var moneyTextfield: String { return "Money2:" }
    var saleLabel: String { return "Money1:" }
    var salesCash: Double { return sale.salesCash }
    var salesSum: Double { return sale.salesSum }
    var typeOfDonation: String { return sale.salesTypeOfDonation }
    
    init(sale: SalesModel, newModel: Bool = false) {
        self.sale = sale
        self.newModel = newModel
    }
    
    func isExist(date: Date, type: String) -> Bool {
        let salesModel = DatabaseManager.shared.fetchSales(date: date, type: type)
        return !salesModel.isEmpty
    }
    
    func saveSales(date: Date, typeOfDonation: String?, salesCash: String?, salesSum: String?) {
        sale = SalesModel()
        sale.salesDate = date
        sale.salesSum = Double(salesSum ?? "0") ?? 0
        sale.salesCash = Double(salesCash ?? "0") ?? 0
        sale.salesTypeOfDonation = typeOfDonation ?? ""
        
        DatabaseManager.shared.saveSalesModel(model: sale)
    }
    
    func updateSales(date: Date, typeOfDonation: String?, salesCash: String?, salesSum: String?) {
        let salesSum = Double(salesSum ?? "0") ?? 0
        let salesCash = Double(salesCash ?? "0") ?? 0
        let typeOfDonation = typeOfDonation ?? ""
        DatabaseManager.shared.updateSalesModel(model: sale, salesDate: date, salesTypeOfDonation: typeOfDonation, salesSum: salesSum, salesCash: salesCash)
    }
    
    func numberOfRowsInComponent(component: Int) -> Int {
        guard let types = self.types else { return 0 }
        return types.count
    }
    
    func titleForRow(row: Int, component: Int) -> String? {
        guard let types = self.types else { return nil }
        return types[row].type
    }
    
    func selectRow(atRow row: Int) {
        self.selectedRow = row
    }
    
}
