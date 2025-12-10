import Foundation

final class HomeViewModel: HomeViewModelType {
  private(set) var todaySum: Double = 0
  private(set) var weekSum: Double = 0
  private(set) var monthSum: Double = 0
  private(set) var monthExpenses: Double = 0
  private(set) var monthProfit: Double = 0
  private(set) var dateToday: Date = Date()

  private(set) var lastIncome: [OrderModel] = []
  private(set) var lastExpense: [CostModel] = []

  @MainActor
  func loadDashboard() async {
    dateToday = Date()

    let orders: [OrderModel] = await withCheckedContinuation { continuation in
      DomainDatabaseService.shared.fetchOrders { models in
        continuation.resume(returning: models)
      }
    }

    let costs: [CostModel] = await withCheckedContinuation { continuation in
      DomainDatabaseService.shared.fetchCosts { models in
        continuation.resume(returning: models)
      }
    }

    computeIncomeMetrics(from: orders)
    computeExpenseMetrics(from: costs)
    computeLists(orders: orders, costs: costs)
  }

  private func computeIncomeMetrics(from orders: [OrderModel]) {
    let cal = Calendar.current
    let today = Date()
    let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
    let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today

    todaySum = orders.filter { cal.isDate($0.date, inSameDayAs: today) }.reduce(0) { $0 + $1.sum }
    weekSum = orders.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.sum }
    monthSum = orders.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.sum }
  }

  private func computeExpenseMetrics(from costs: [CostModel]) {
    let cal = Calendar.current
    let today = Date()
    let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today

    monthExpenses = costs.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.sum }
    monthProfit = monthSum - monthExpenses
  }

  private func computeLists(orders: [OrderModel], costs: [CostModel]) {
    lastIncome = orders.sorted { $0.date > $1.date }.prefix(3).map { $0 }
    lastExpense = costs.sorted { $0.date > $1.date }.prefix(3).map { $0 }
  }
}

