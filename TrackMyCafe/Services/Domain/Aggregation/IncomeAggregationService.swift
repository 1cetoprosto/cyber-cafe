import Foundation

struct IncomeSummary {
    let sales: Double
    let cash: Double
    let card: Double
    let cogs: Double
    let count: Int
    let last: [OrderModel]
}

protocol IncomeAggregationServiceProtocol {
    func summarize(orders: [OrderModel], period: DashboardPeriod, referenceDate: Date)
        -> IncomeSummary
}

final class IncomeAggregationService: IncomeAggregationServiceProtocol {
    func summarize(orders: [OrderModel], period: DashboardPeriod, referenceDate: Date)
        -> IncomeSummary
    {
        let interval = period.interval(for: referenceDate)
        let filtered = orders.filter { order in
            order.date >= interval.start && order.date <= interval.end
        }
        let sales = filtered.reduce(0) { $0 + $1.sum }
        let cash = filtered.reduce(0) { $0 + $1.cash }
        let card = filtered.reduce(0) { $0 + $1.card }
        let cogs = filtered.reduce(0) { $0 + $1.totalCost }
        let last = filtered.sorted { $0.date > $1.date }.prefix(3).map { $0 }
        return IncomeSummary(
            sales: sales, cash: cash, card: card, cogs: cogs, count: filtered.count, last: last)
    }
}
