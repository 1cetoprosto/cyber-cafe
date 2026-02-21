//
//  OrderDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

enum OrderSaveError: Error {
    case stockValidationFailed([StockWarning])
    case saveFailed
    case fetchFailed
}

protocol OrderDetailsViewModelType {
    // Properties
    var productsViewModel: ProductListViewModel { get }
    
    var id: String { get }
    var date: Date { get }
    var cashLabel: String { get }
    var cardLabel: String { get }
    var cashTextfield: String { get }
    var cardTextfield: String { get }
    var orderLabel: String { get }
    var cash: Double { get }
    var card: Double { get }
    var sum: Double { get }
    var type: String { get }
    var isNewModel: Bool { get set }
    
    // Methods
    func loadProducts(completion: @escaping () -> Void)
    func save(date: Date, type: String?, cash: String?, card: String?, ignoreStockWarning: Bool, completion: @escaping (Result<Void, OrderSaveError>) -> Void)
    func deleteOrder(completion: @escaping () -> Void)
    
    // Picker Data Source
    func numberOfRowsInComponent(component: Int) -> Int
    func titleForRow(row: Int, component: Int) -> String?
    func selectRow(atRow row: Int)
    
    // Helpers
    func verifyRequiredData(completion: @escaping (Bool) -> Void)
}
