//
//  OrderDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class OrderDetailsViewModel: OrderDetailsViewModelType, Loggable {

    // MARK: - Properties
    private var order: OrderModel
    private var types: [TypeModel] = []
    private var selectedRow: Int?
    private let orderDataService: OrderDataServiceProtocol

    let productsViewModel: ProductListViewModel

    private var orderTrackingMode: Bool {
        isNewModel
            ? SettingsManager.shared.loadTrackIngredients()
            : order.inventoryTracking
    }

    var id: String { return order.id }
    var date: Date { return order.date }
    var cashLabel: String { return R.string.global.receivedInCash() }
    var cardLabel: String { return R.string.global.receivedByCard() }
    var cashTextfield: String { return R.string.global.money2() }
    var cardTextfield: String { return R.string.global.money3() }
    var orderLabel: String { return R.string.global.totalTitle() }
    var cash: Double { return order.cash }
    var card: Double { return order.card }
    var sum: Double { return order.sum }
    var type: String { return order.type }
    var note: String { return order.note ?? "" }
    var isNewModel: Bool

    // MARK: - Init
    init(
        model: OrderModel,
        isNewModel: Bool = false,
        orderDataService: OrderDataServiceProtocol = DomainOrderDataService()
    ) {
        self.order = model
        self.isNewModel = isNewModel
        self.orderDataService = orderDataService
        self.productsViewModel = ProductListViewModel()
        self.productsViewModel.inventoryTrackingMode =
            (isNewModel
                ? SettingsManager.shared.loadTrackIngredients()
                : model.inventoryTracking)

        fetchTypes()
    }

    // MARK: - Data Loading
    func loadProducts() async {
        let mode = SettingsManager.shared.loadOrderEntryMode()
        switch mode {
        case .perOrder:
            if isNewModel {
                productsViewModel.clearProducts()
            } else {
                await productsViewModel.getProducts(withIdOrder: order.id)
            }
        case .openTab:
            let orderId = isNewModel ? "" : order.id
            await productsViewModel.getProducts(withIdOrder: orderId)
        }
    }

    // MARK: - Saving Logic
    func save(
        date: Date,
        type: String?,
        cash: String?,
        card: String?,
        note: String?,
        ignoreStockWarning: Bool
    ) async throws {
        let type = type ?? ""
        let cashValue = cash?.double ?? 0.0
        let cardValue = card?.double ?? 0.0
        let note = note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if !ignoreStockWarning {
            let warnings = await productsViewModel.validateStock()
            if !warnings.isEmpty {
                throw OrderSaveError.stockValidationFailed(warnings)
            }
        }

        try await performSave(date: date, type: type, cash: cashValue, card: cardValue, note: note)
    }

    private func performSave(
        date: Date, type: String, cash: Double, card: Double, note: String?
    ) async throws {
        if isNewModel {
            let success = await createOrder(
                date: date, type: type, cash: cash, card: card, note: note)
            guard success else { throw OrderSaveError.saveFailed }

            let productsSaved = await productsViewModel.saveOrder(withOrderId: order.id, date: date)
            guard productsSaved else { throw OrderSaveError.saveFailed }
        } else {
            let success = await updateOrder(
                date: date, type: type, cash: cash, card: card, note: note)
            guard success else { throw OrderSaveError.saveFailed }

            let productsSaved = await productsViewModel.updateOrder(orderId: order.id, date: date)
            guard productsSaved else { throw OrderSaveError.saveFailed }
        }
    }

    private func createOrder(
        date: Date, type: String, cash: Double, card: Double, note: String?
    ) async -> Bool {
        let sum = productsViewModel.getTotalAmount()
        let totalCost = productsViewModel.getTotalCostAmount()

        let newOrder = OrderModel(
            id: id,
            date: date,
            type: type,
            sum: sum,
            cash: cash,
            card: card,
            totalCost: totalCost,
            inventoryTracking: orderTrackingMode,
            note: note,
            createdBy: UserSession.current.employeeRef
        )

        do {
            let savedOrder = try await orderDataService.createOrder(newOrder)
            order = savedOrder
            isNewModel = false
            return true
        } catch {
            logger.error(
                "Failed to create order \(newOrder.id): \(error.localizedDescription)")
            return false
        }
    }

    private func updateOrder(
        date: Date, type: String, cash: Double, card: Double, note: String?
    ) async -> Bool {
        let sum = productsViewModel.getTotalAmount()
        let totalCost = productsViewModel.getTotalCostAmount()

        let updatedOrder = OrderModel(
            id: order.id,
            date: date,
            type: type,
            sum: sum,
            cash: cash,
            card: card,
            totalCost: totalCost,
            inventoryTracking: orderTrackingMode,
            note: note,
            createdBy: order.createdBy
        )

        do {
            try await orderDataService.updateOrder(previous: order, current: updatedOrder)
            order = updatedOrder
            return true
        } catch {
            logger.error(
                "Failed to update order \(updatedOrder.id): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Picker Data Source
    func numberOfRowsInComponent(component: Int) -> Int {
        return types.count
    }

    func titleForRow(row: Int, component: Int) -> String? {
        return types[row].name
    }

    func selectRow(atRow row: Int) {
        self.selectedRow = row
    }

    func getSelectedType() -> String? {
        guard let row = selectedRow, row < types.count else { return nil }
        return types[row].name
    }

    // MARK: - Helpers
    func fetchTypes() {
        Task { [weak self] in
            let types = await DomainDatabaseService.shared.fetchTypes()
            self?.types = types
            if let index = types.firstIndex(where: { $0.name == self?.order.type }) {
                self?.selectedRow = index
            }
        }
    }

    func verifyRequiredData() async -> Bool {
        let types = await DomainDatabaseService.shared.fetchTypes()
        self.types = types
        let productPrices = await DomainDatabaseService.shared.fetchProductsPrice()
        return !types.isEmpty && !productPrices.isEmpty
    }

    func deleteOrder() async {
        ProductListViewModel.deleteOrder(
            withOrderId: id,
            date: date,
            trackingEnabled: orderTrackingMode
        )

        do {
            try await orderDataService.deleteOrder(order)
            logger.notice("Order deleted")
        } catch {
            logger.error(
                "Failed to delete order \(order.id): \(error.localizedDescription)")
        }
    }
}
