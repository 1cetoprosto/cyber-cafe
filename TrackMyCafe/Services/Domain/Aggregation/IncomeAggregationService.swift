import Foundation

struct IncomeSummary {
    let sales: Double
    let cash: Double
    let card: Double
    let last: [OrderModel]
}

protocol IncomeAggregationServiceProtocol {
    func summarize(orders: [OrderModel], period: DashboardPeriod, referenceDate: Date) -> IncomeSummary
}

final class IncomeAggregationService: IncomeAggregationServiceProtocol {
    func summarize(orders: [OrderModel], period: DashboardPeriod, referenceDate: Date) -> IncomeSummary {
        let interval = Self.interval(for: period, referenceDate: referenceDate)
        let filtered = orders.filter { order in
            order.date >= interval.start && order.date <= interval.end
        }
        let sales = filtered.reduce(0) { $0 + $1.sum }
        let cash = filtered.reduce(0) { $0 + $1.cash }
        let card = filtered.reduce(0) { $0 + $1.card }
        let last = filtered.sorted { $0.date > $1.date }.prefix(3).map { $0 }
        return IncomeSummary(sales: sales, cash: cash, card: card, last: last)
    }
    
    private static func interval(for period: DashboardPeriod, referenceDate: Date) -> DateInterval {
        let cal = Calendar.current
        switch period {
        case .day:
            let start = cal.startOfDay(for: referenceDate)
            let end = cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? referenceDate
            return DateInterval(start: start, end: end)
        case .week:
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            let start = cal.date(from: comps) ?? referenceDate
            let end = cal.date(byAdding: DateComponents(day: 7, second: -1), to: start) ?? referenceDate
            return DateInterval(start: start, end: end)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: referenceDate)
            let start = cal.date(from: comps) ?? referenceDate
            let nextMonth = cal.date(byAdding: DateComponents(month: 1), to: start) ?? referenceDate
            let end = cal.date(byAdding: DateComponents(second: -1), to: nextMonth) ?? referenceDate
            return DateInterval(start: start, end: end)
        }
    }
}

