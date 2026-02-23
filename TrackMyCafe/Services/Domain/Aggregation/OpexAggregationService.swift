import Foundation

struct OpexSummary {
    let total: Double
    let last: [OpexExpenseModel]
}

protocol OpexAggregationServiceProtocol {
    func summarize(expenses: [OpexExpenseModel], period: DashboardPeriod, referenceDate: Date) -> OpexSummary
}

final class OpexAggregationService: OpexAggregationServiceProtocol {
    func summarize(expenses: [OpexExpenseModel], period: DashboardPeriod, referenceDate: Date) -> OpexSummary {
        let interval = Self.interval(for: period, referenceDate: referenceDate)
        let filtered = expenses.filter { expense in
            expense.date >= interval.start && expense.date <= interval.end
        }
        let total = filtered.reduce(0) { $0 + $1.amount }
        let last = filtered.sorted { $0.date > $1.date }.prefix(3).map { $0 }
        return OpexSummary(total: total, last: last)
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

