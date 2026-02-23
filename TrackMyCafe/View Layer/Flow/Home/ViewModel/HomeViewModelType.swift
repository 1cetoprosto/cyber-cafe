import Foundation

protocol HomeViewModelType {
    var todaySum: Double { get }
    var weekSum: Double { get }
    var monthSum: Double { get }
    var monthExpenses: Double { get }
    var monthProfit: Double { get }
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
