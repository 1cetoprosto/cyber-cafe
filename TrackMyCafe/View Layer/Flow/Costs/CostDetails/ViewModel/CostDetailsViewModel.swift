//
//  CostDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class CostDetailsViewModel: CostDetailsViewModelType {
    
    private var cost: CostModel
    //var newModel: Bool
    
    var costDate: Date { return cost.date }
    var costName: String { return cost.name }
    var costSum: String { return cost.sum.description }
    
    func saveCostModel(costDate: Date, costName: String?, costSum: String?) {

        let costName = costName ?? ""
        let costSum = costSum?.doubleOrZero
        
        //if newModel {
            cost.date = costDate
            cost.name = costName
            cost.sum = costSum ?? 0.0
            
        if cost.id.isEmpty {
            cost.id = UUID().uuidString
            DomainDatabaseService.shared.saveCost(model: cost) { success in
                if success {
                    print("Cost saved successfully")
                } else {
                    print("Failed to save Cost")
                }
            }
        } else {
            DomainDatabaseService.shared.updateCost(model: cost, date: costDate, name: costName, sum: costSum ?? 0.0)
        }
    }
    
    init(cost: CostModel) {
        self.cost = cost
        //self.newModel = true
    }
    
}
