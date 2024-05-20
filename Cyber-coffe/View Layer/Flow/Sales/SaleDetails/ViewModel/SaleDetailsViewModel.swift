//
//  SaleDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class SaleDetailsViewModel: SaleDetailsViewModelType {
    
    private var sale: DailySalesModel
    private var types: [IncomeTypeModel]  = []
    private var selectedRow: Int?
    var isNewModel: Bool
    
    var date: Date { return sale.date}
    var cashLabel: String { return "Cash:" }
    var cardLabel: String { return "Card:" }
    var cashTextfield: String { return "Money2:" }
    var cardTextfield: String { return "Money3:" }
    var saleLabel: String { return "Money1:" }
    var cash: Double { return sale.cash }
    var card: Double { return sale.card }
    var sum: Double { return sale.sum }
    var incomeType: String { return sale.incomeType }
    
    init(model: DailySalesModel, isNewModel: Bool = false) {
        self.sale = model
        self.isNewModel = isNewModel
    }
    
    func isExist(date: Date, type: String, completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchSales(forDate: date, ofType: type) { dailySales in
            completion(dailySales.isEmpty)
        }
    }
    
    func saveSales(date: Date, incomeType: String?, cash: String?, card: String?, sum: String?) {
        let dailySale = DailySalesModel(
                id: "",
                date: date,
                incomeType: incomeType ?? "",
                sum: sum?.double ?? 0.0,
                cash: cash?.double ?? 0.0,
                card: card?.double ?? 0.0
            )
        
        DomainDatabaseService.shared.saveDailySale(sale: dailySale) { success in
                if success {
                    print("Sale saved successfully")
                } else {
                    print("Failed to save sale")
                }
            }
    }
    
    func updateSales(date: Date, incomeType: String?, cash: String?, card: String?, sum: String?) {
        
        DomainDatabaseService.shared.fetchSales(forDate: date, ofType: incomeType) { dailySales in
            for dailySale in dailySales {
                DomainDatabaseService.shared.updateSales(model: dailySale,
                                                         date: date,
                                                         incomeType: incomeType ?? "",
                                                         total: sum?.double ?? 0.0,
                                                         cashAmount: cash?.double ?? 0.0,
                                                         cardAmount: card?.double ?? 0.0)
            }
        }
        
        
        
//        let salesSynchronized = FirestoreDatabaseService.shared.update(firModel: FIRDailySalesModel(salesId: sale.id,
//                                                                salesDate: date,
//                                                                salesTypeOfDonation: typeOfDonation,
//                                                                salesSum: salesSum,
//                                                                salesCash: salesCash,
//                                                                salesCard: salesCard),
//                                        collection: "sales",
//                                        documentId: sale.id)
//        
//        RealmDatabaseService.shared.updateSales(model: sale,
//                                                date: date,
//                                                incomeType: typeOfDonation,
//                                                total: salesSum,
//                                                cashAmount: salesCash,
//                                                cardAmount: salesCard)
    }
    
    func numberOfRowsInComponent(component: Int) -> Int {
        //guard let types = self.types else { return 0 }
        return types.count
    }
    
    func titleForRow(row: Int, component: Int) -> String? {
        //guard let types = self.types else { return nil }
        return types[row].name
    }
    
    func selectRow(atRow row: Int) {
        self.selectedRow = row
    }
    
}
