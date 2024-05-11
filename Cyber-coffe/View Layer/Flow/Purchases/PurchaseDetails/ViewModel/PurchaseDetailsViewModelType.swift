//
//  PurchaseDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol PurchaseDetailsViewModelType {
    var purchaseDate: Date { get }
    var purchaseName: String { get }
    var purchaseSum: String { get }
    
    var newModel: Bool { get set }
    
    func savePurchaseModel(purchaseDate: Date, purchaseName: String?, purchaseSum: String?)
    // TODO: Boxing
    //var age: Box<String?> { get }
}
