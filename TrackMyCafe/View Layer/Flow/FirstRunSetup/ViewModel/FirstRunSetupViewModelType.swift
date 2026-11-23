//
//  FirstRunSetupViewModelType.swift
//  TrackMyCafe
//
//  Created on 23.11.2026.
//

import Foundation

// MARK: - FirstRunSetupStep

enum FirstRunSetupStep: Int, CaseIterable {
    case preferencesStock = 0
    case preferencesReceipt = 1
    case preferencesTypes = 2
    case menu = 3
    case firstSale = 4
    case expense = 5
    case leftover = 6

    var displayNumber: Int { rawValue + 1 }
    static var totalCount: Int { allCases.count }

    static let preferencesStepCount = 3

    var isPreferencesStep: Bool {
        switch self {
        case .preferencesStock, .preferencesReceipt, .preferencesTypes:
            return true
        default:
            return false
        }
    }

    var preferencesDisplayNumber: Int? {
        switch self {
        case .preferencesStock: return 1
        case .preferencesReceipt: return 2
        case .preferencesTypes: return 3
        default: return nil
        }
    }
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
    /// When true, only the three operating-profile steps are shown, then the flow finishes.
    var isPreferencesOnly: Bool { get }

    /// Draft operating choices (applied when leaving the types step).
    var tracksIngredients: Bool { get }
    var orderEntryMode: OrderEntryMode { get }
    var chooseCategoryFirst: Bool { get }
    var wantsMultipleReceiptTypes: Bool { get }

    var onStepChanged: (() -> Void)? { get set }
    var onProductsChanged: (() -> Void)? { get set }
    var onSaleChanged: (() -> Void)? { get set }
    var onSummaryReady: (() -> Void)? { get set }
    var onCompleted: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onPreferencesChanged: (() -> Void)? { get set }

    func canContinueFromCurrentStep() -> Bool
    func setTracksIngredients(_ enabled: Bool)
    func setOrderEntryMode(_ mode: OrderEntryMode)
    func setChooseCategoryFirst(_ enabled: Bool)
    func setWantsMultipleReceiptTypes(_ enabled: Bool)
    func commitOperatingPreferencesAndTypes() async
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
