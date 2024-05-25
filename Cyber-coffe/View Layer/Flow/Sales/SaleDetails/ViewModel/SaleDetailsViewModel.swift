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
    
    var id: String { return sale.id }
    var date: Date { return sale.date }
    var cashLabel: String { return "Cash:" }
    var cardLabel: String { return "Card:" }
    var cashTextfield: String { return "Money2:" }
    var cardTextfield: String { return "Money3:" }
    var saleLabel: String { return "Money1:" }
    var cash: Double { return sale.cash }
    var card: Double { return sale.card }
    var sum: Double { return sale.sum }
    var incomeType: String { return sale.incomeType }
    var isNewModel: Bool
    
    init(model: DailySalesModel, isNewModel: Bool = false) {
        self.sale = model
        self.isNewModel = isNewModel
        fetchIncomeTypes()
    }
    
    func isExist(id: String, completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchSales(forId: id) { dailySale in
            completion(dailySale != nil)
        }
    }
    
    func saveSales(id: String, date: Date, incomeType: String?, cash: String?, card: String?, sum: String?) {
        let dailySale = DailySalesModel(
            id: id,
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
    
    func updateSales(id: String, date: Date, incomeType: String?, cash: String?, card: String?, sum: String?) {
        
        DomainDatabaseService.shared.fetchSales(forId: id) { dailySale in
            guard let dailySale = dailySale else { return }
                DomainDatabaseService.shared.updateSales(model: dailySale,
                                                         date: date,
                                                         incomeType: incomeType ?? "",
                                                         total: sum?.double ?? 0.0,
                                                         cashAmount: cash?.double ?? 0.0,
                                                         cardAmount: card?.double ?? 0.0)
            //}
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
    
    func fetchIncomeTypes() {
        DomainDatabaseService.shared.fetchIncomeTypes { [weak self] incomeTypes in
            self?.types = incomeTypes
        }
    }
    
    // New method to check if required data exists
    func verifyRequiredData(completion: @escaping (Bool) -> Void) {
        DomainDatabaseService.shared.fetchIncomeTypes { [weak self] incomeTypes in
            guard let self = self else { return }
            self.types = incomeTypes
            DomainDatabaseService.shared.fetchGoodsPrice { goodPrices in
                completion(!incomeTypes.isEmpty && !goodPrices.isEmpty)
            }
        }
    }
}
