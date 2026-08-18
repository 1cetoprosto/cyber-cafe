import Foundation

struct ProfitSummary {
    let sales: Double
    let cogs: Double
    let grossProfit: Double
    let opex: Double
    let netProfit: Double
    let grossMarginPercent: Double
}

protocol FinanceAggregationServiceProtocol {
    func computeNetProfit(sales: Double, opex: Double) -> Double
    func summarize(income: IncomeSummary, opex: OpexSummary) -> ProfitSummary
}

final class FinanceAggregationService: FinanceAggregationServiceProtocol {
    func computeNetProfit(sales: Double, opex: Double) -> Double {
        sales - opex
    }

    func summarize(income: IncomeSummary, opex: OpexSummary) -> ProfitSummary {
        let sales = income.sales
        let cogs = income.cogs
        let opexTotal = opex.total
        let grossProfit = sales - cogs
        let netProfit = grossProfit - opexTotal
        let grossMarginPercent: Double
        if sales == 0 {
            grossMarginPercent = 0
        } else {
            grossMarginPercent = (grossProfit / sales) * 100
        }
        return ProfitSummary(
            sales: sales,
            cogs: cogs,
            grossProfit: grossProfit,
            opex: opexTotal,
            netProfit: netProfit,
            grossMarginPercent: grossMarginPercent
        )
    }
}

