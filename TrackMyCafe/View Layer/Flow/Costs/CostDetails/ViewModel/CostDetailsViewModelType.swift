//
//  CostDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol CostDetailsViewModelType {
    var costDate: Date { get }
    var costName: String { get }
    var costSum: String { get }
    
    //var newModel: Bool { get set }
    
    func saveCostModel(costDate: Date, costName: String?, costSum: String?)
    // TODO: Boxing
    //var age: Box<String?> { get }
}
