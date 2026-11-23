//
//  FirstRunSetupViewModel.swift
//  TrackMyCafe
//
//  Created on 23.11.2026.
//

import Foundation

// MARK: - FirstRunSetupViewModel

final class FirstRunSetupViewModel: FirstRunSetupViewModelType, Loggable {

    // MARK: - Properties

    private(set) var currentStep: FirstRunSetupStep = .menu
    private(set) var addedProducts: [ProductsPriceModel] = []
    private(set) var saleLines: [FirstRunSetupSaleLine] = []
    private(set) var salesTotal: Double = 0
    private(set) var costsTotal: Double = 0
    private(set) var leftoverTotal: Double = 0

    let minimumProductsToContinue = 2

    var onStepChanged: (() -> Void)?
    var onProductsChanged: (() -> Void)?
    var onSaleChanged: (() -> Void)?
    var onSummaryReady: (() -> Void)?
    var onCompleted: (() -> Void)?
    var onError: ((String) -> Void)?

    private let database: DomainDB
    private let defaults: UserDefaults

    // MARK: - Init

    init(
        database: DomainDB = DomainDatabaseService.shared,
        defaults: UserDefaults = .standard
    ) {
        self.database = database
        self.defaults = defaults
    }

    // MARK: - FirstRunSetupViewModelType

    func canContinueFromCurrentStep() -> Bool {
        switch currentStep {
        case .menu:
            return addedProducts.count >= minimumProductsToContinue
        case .firstSale:
            return saleLines.contains(where: { $0.quantity > 0 })
        case .expense:
            return false
        case .leftover:
            return true
        }
    }

    @MainActor
    func addProduct(name: String, priceText: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?(R.string.global.firstRunProductNameRequired())
            return false
        }
        guard let price = parsedAmount(from: priceText), price >= 0 else {
            onError?(R.string.global.firstRunProductPriceInvalid())
            return false
        }

        let product = ProductsPriceModel(
            id: UUID().uuidString,
            name: trimmed,
            price: price
        )
        let success = await database.saveProductsPrice(productPrice: product)
        guard success else {
            onError?(R.string.global.error())
            logger.error("Failed to save first-run product")
            return false
        }

        addedProducts.append(product)
        rebuildSaleLinesPreservingQuantities()
        onProductsChanged?()
        onSaleChanged?()
        return true
    }

    func setSaleQuantity(productId: String, quantity: Int) {
        guard let index = saleLines.firstIndex(where: { $0.product.id == productId }) else {
            return
        }
        saleLines[index].quantity = max(0, quantity)
        onSaleChanged?()
    }

    @MainActor
    func saveFirstSale() async -> Bool {
        let selected = saleLines.filter { $0.quantity > 0 }
        guard !selected.isEmpty else {
            onError?(R.string.global.firstRunSaleEmpty())
            return false
        }

        let types = await database.fetchTypes()
        let orderType =
            types.first(where: { $0.isDefault })?.name
            ?? types.first?.name
            ?? DefaultValues.defaultOrderType

        let orderId = UUID().uuidString
        let date = Date()
        let sum = selected.reduce(0.0) {
            $0 + ($1.product.price * Double($1.quantity))
        }

        let order = OrderModel(
            id: orderId,
            date: date,
            type: orderType,
            sum: sum,
            cash: sum,
            card: 0,
            totalCost: 0,
            inventoryTracking: false,
            note: nil,
            createdBy: UserSession.current.employeeRef
        )

        guard let savedOrderId = await database.saveOrder(order: order) else {
            onError?(R.string.global.error())
            logger.error("Failed to save first-run order")
            return false
        }

        for line in selected {
            let item = OrderItemModel(
                id: UUID().uuidString,
                productId: line.product.id,
                name: line.product.name,
                orderId: savedOrderId,
                date: date,
                quantity: line.quantity,
                salePrice: line.product.price,
                costPrice: 0
            )
            let itemId = await database.saveProduct(order: item)
            if itemId == nil {
                logger.error("Failed to save first-run order item for \(line.product.name)")
            }
        }

        salesTotal = sum
        return true
    }

    @MainActor
    func saveExpense(name: String, amountText: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?(R.string.global.firstRunExpenseNameRequired())
            return false
        }
        guard let amount = parsedAmount(from: amountText), amount >= 0 else {
            onError?(R.string.global.firstRunExpenseAmountInvalid())
            return false
        }

        let expense = OpexExpenseModel(
            id: UUID().uuidString,
            date: Date(),
            categoryId: "General",
            amount: amount,
            paymentAccount: .cash,
            note: trimmed
        )

        guard await database.saveOpexExpense(model: expense) != nil else {
            onError?(R.string.global.error())
            logger.error("Failed to save first-run expense")
            return false
        }

        costsTotal = amount
        return true
    }

    func advanceAfterSuccessfulAction() {
        guard let next = FirstRunSetupStep(rawValue: currentStep.rawValue + 1) else {
            finishSetup()
            return
        }
        currentStep = next
        if currentStep == .leftover {
            refreshSummary()
        }
        onStepChanged?()
    }

    func skipCurrentStep() {
        advanceAfterSuccessfulAction()
    }

    func skipEntireSetup() {
        markCompleted()
        onCompleted?()
    }

    func finishSetup() {
        markCompleted()
        onCompleted?()
    }

    func refreshSummary() {
        leftoverTotal = salesTotal - costsTotal
        onSummaryReady?()
    }

    // MARK: - Private

    private func rebuildSaleLinesPreservingQuantities() {
        let previousQuantities = Dictionary(
            uniqueKeysWithValues: saleLines.map { ($0.product.id, $0.quantity) }
        )
        saleLines = addedProducts.map { product in
            FirstRunSetupSaleLine(
                product: product,
                quantity: previousQuantities[product.id] ?? 0
            )
        }
    }

    private func markCompleted() {
        defaults.set(true, forKey: UserDefaultsKeys.hasCompletedFirstRunSetup)
    }

    private func parsedAmount(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: trimmed)?.doubleValue {
            return number
        }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
