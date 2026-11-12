import Foundation

protocol HomeViewModelType {
    var todaySum: Double { get }
    var weekSum: Double { get }
    var monthSum: Double { get }
    var periodExpenses: Double { get }
    var periodProfit: Double { get }
    /// Net profit for the previous day / week / month. `nil` if interval cannot be resolved.
    var previousPeriodProfit: Double? { get }
    /// `((current - previous) / |previous|) * 100`. `nil` when comparison is unavailable.
    var periodProfitDeltaPercent: Double? { get }
    var dateToday: Date { get }
    var cashBalance: Double { get }
    var cardBalance: Double { get }

    var lastIncome: [OrderModel] { get }
    var lastExpense: [OpexExpenseModel] { get }

    @MainActor
    func loadDashboard() async

    func setPeriod(_ period: DashboardPeriod)
    func recomputeForCurrentData()
}
