//
//  CostDetailsViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

class CostDetailsViewModel: CostDetailsViewModelType, Loggable {
    private var cost: CostModel
    private let dataService: CostDataServiceProtocol

    var costDate: Date { cost.date }
    var costName: String { cost.name }
    var costSum: Double { cost.sum }

    init(cost: CostModel, dataService: CostDataServiceProtocol) {
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

        cost.date = costDate
        cost.name = name
        cost.sum = sum

        if cost.id.isEmpty {
            cost.id = UUID().uuidString
            do {
                try await dataService.saveCost(cost)
                logger.notice("Cost \(cost.id) saved successfully")
            } catch {
                logger.error("Failed to save Cost \(cost.id)")
                throw error
            }
        } else {
            await dataService.updateCost(cost, date: costDate, name: name, sum: sum)
            logger.notice("Cost \(cost.id) updated successfully")
        }
    }
}
