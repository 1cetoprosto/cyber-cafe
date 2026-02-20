//
//  CostDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class CostDetailsViewModel: CostDetailsViewModelType, Loggable {
    private var cost: OpexExpenseModel
    private let dataService: CostDataServiceProtocol

    var costDate: Date { cost.date }
    var costName: String { cost.note ?? "" }
    var costSum: Double { cost.amount }

    init(cost: OpexExpenseModel, dataService: CostDataServiceProtocol) {
        self.cost = cost
        self.dataService = dataService
    }

    func validate(name: String?, sumText: String?) -> Bool {
        guard let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let sum = parsedSum(from: sumText), sum >= 0 else { return false }
        return true
    }

    func parsedSum(from text: String?) -> Double? {
        guard let text = text, !text.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter.number(from: text)?.doubleValue ?? Double(text.replacingOccurrences(of: ",", with: "."))
    }

    @MainActor
    func saveCostModel(costDate: Date, costName: String?, costSum: Double?) async throws {
        let name = (costName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let sum = costSum ?? 0.0

        // Create new model with updated values since structs are immutable
        var updatedCost = OpexExpenseModel(
            id: cost.id,
            date: costDate,
            categoryId: cost.categoryId,
            amount: sum,
            note: name
        )

        if updatedCost.id.isEmpty {
            updatedCost = OpexExpenseModel(
                id: UUID().uuidString,
                date: costDate,
                categoryId: "General", // Default category for new items
                amount: sum,
                note: name
            )
            do {
                try await dataService.saveCost(updatedCost)
                logger.notice("Cost \(updatedCost.id) saved successfully")
            } catch {
                logger.error("Failed to save Cost \(updatedCost.id)")
                throw error
            }
        } else {
            await dataService.updateCost(updatedCost, date: costDate, name: name, sum: sum)
            logger.notice("Cost \(updatedCost.id) updated successfully")
        }
    }
}
