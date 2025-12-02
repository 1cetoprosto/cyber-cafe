//
//  CostListItemViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class CostListItemViewModel: CostListItemViewModelType {
    
    private var cost: CostModel
    
    var costDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        return dateFormatter.string(from: cost.date)
    }
    
    var costName: String {
        return cost.name
    }
    
  var costSum: String {
        return cost.sum.currency
  }
    
    init(cost: CostModel) {
        self.cost = cost
    }
}
