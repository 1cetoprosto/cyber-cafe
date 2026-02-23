import Foundation

protocol FinanceAggregationServiceProtocol {
    func computeNetProfit(sales: Double, opex: Double) -> Double
}

final class FinanceAggregationService: FinanceAggregationServiceProtocol {
    func computeNetProfit(sales: Double, opex: Double) -> Double {
        sales - opex
    }
}

