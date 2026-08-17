import Foundation

struct OpexSummary {
    let total: Double
    let count: Int
    let last: [OpexExpenseModel]
}

protocol OpexAggregationServiceProtocol {
    func summarize(expenses: [OpexExpenseModel], period: DashboardPeriod, referenceDate: Date)
        -> OpexSummary
    func summarize(expenses: [OpexExpenseModel], intervalStart: Date, intervalEnd: Date)
        -> OpexSummary
}

final class OpexAggregationService: OpexAggregationServiceProtocol {
    func summarize(expenses: [OpexExpenseModel], period: DashboardPeriod, referenceDate: Date)
        -> OpexSummary
    {
        let interval = period.interval(for: referenceDate)
        return summarize(
            expenses: expenses, intervalStart: interval.start, intervalEnd: interval.end)
    }

    func summarize(expenses: [OpexExpenseModel], intervalStart: Date, intervalEnd: Date)
        -> OpexSummary
    {
        let filtered = expenses.filter { expense in
            expense.date >= intervalStart && expense.date < intervalEnd
        }
        let total = filtered.reduce(0) { $0 + $1.amount }
        let last = filtered.sorted { $0.date > $1.date }.prefix(3).map { $0 }
        return OpexSummary(total: total, count: filtered.count, last: last)
    }
}
