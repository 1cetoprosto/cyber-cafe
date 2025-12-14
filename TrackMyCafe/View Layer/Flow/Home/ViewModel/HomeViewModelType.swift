import Foundation

protocol HomeViewModelType {
  var todaySum: Double { get }
  var weekSum: Double { get }
  var monthSum: Double { get }
  var monthExpenses: Double { get }
  var monthProfit: Double { get }
  var dateToday: Date { get }

  var lastIncome: [OrderModel] { get }
  var lastExpense: [CostModel] { get }

  @MainActor
  func loadDashboard() async
}

