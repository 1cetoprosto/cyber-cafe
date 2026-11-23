//
//  FirstRunSetupViewModelType.swift
//  TrackMyCafe
//
//  Created on 23.11.2026.
//

import Foundation

// MARK: - FirstRunSetupStep

enum FirstRunSetupStep: Int, CaseIterable {
    case menu = 0
    case firstSale = 1
    case expense = 2
    case leftover = 3

    var displayNumber: Int { rawValue + 1 }
    static var totalCount: Int { allCases.count }
}

// MARK: - FirstRunSetupSaleLine

struct FirstRunSetupSaleLine {
    let product: ProductsPriceModel
    var quantity: Int
}

// MARK: - FirstRunSetupViewModelType

protocol FirstRunSetupViewModelType: AnyObject {
    var currentStep: FirstRunSetupStep { get }
    var addedProducts: [ProductsPriceModel] { get }
    var saleLines: [FirstRunSetupSaleLine] { get }
    var salesTotal: Double { get }
    var costsTotal: Double { get }
    var leftoverTotal: Double { get }
    var minimumProductsToContinue: Int { get }

    var onStepChanged: (() -> Void)? { get set }
    var onProductsChanged: (() -> Void)? { get set }
    var onSaleChanged: (() -> Void)? { get set }
    var onSummaryReady: (() -> Void)? { get set }
    var onCompleted: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }

    func canContinueFromCurrentStep() -> Bool
    func addProduct(name: String, priceText: String) async -> Bool
    func setSaleQuantity(productId: String, quantity: Int)
    func saveFirstSale() async -> Bool
    func saveExpense(name: String, amountText: String) async -> Bool
    func advanceAfterSuccessfulAction()
    func skipCurrentStep()
    func skipEntireSetup()
    func finishSetup()
    func refreshSummary()
}
