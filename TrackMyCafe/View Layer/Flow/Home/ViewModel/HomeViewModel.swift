import Foundation

final class HomeViewModel: HomeViewModelType {
    private let incomeService: IncomeAggregationServiceProtocol
    private let opexService: OpexAggregationServiceProtocol
    private let financeService: FinanceAggregationServiceProtocol
    
    private var currentPeriod: DashboardPeriod = .month
    private var allOrders: [OrderModel] = []
    private var allExpenses: [OpexExpenseModel] = []
    
    private(set) var todaySum: Double = 0
    private(set) var weekSum: Double = 0
    private(set) var monthSum: Double = 0
    private(set) var monthExpenses: Double = 0
    private(set) var monthProfit: Double = 0
    private(set) var dateToday: Date = Date()
    private(set) var cashBalance: Double = 0
    private(set) var cardBalance: Double = 0

    private(set) var lastIncome: [OrderModel] = []
    private(set) var lastExpense: [OpexExpenseModel] = []
    
    init(
        incomeService: IncomeAggregationServiceProtocol = IncomeAggregationService(),
        opexService: OpexAggregationServiceProtocol = OpexAggregationService(),
        financeService: FinanceAggregationServiceProtocol = FinanceAggregationService()
    ) {
        self.incomeService = incomeService
        self.opexService = opexService
        self.financeService = financeService
    }

    @MainActor
    func loadDashboard() async {
        dateToday = Date()

        let orders: [OrderModel] = await withCheckedContinuation { continuation in
            DomainDatabaseService.shared.fetchOrders { models in
                continuation.resume(returning: models)
            }
        }

        let costs: [OpexExpenseModel] = await withCheckedContinuation { continuation in
            DomainDatabaseService.shared.fetchOpexExpenses { models in
                continuation.resume(returning: models)
            }
        }
        
        allOrders = orders
        allExpenses = costs
        
        recomputeForCurrentData()
    }

    func setPeriod(_ period: DashboardPeriod) {
        currentPeriod = period
        recomputeForCurrentData()
    }

    func recomputeForCurrentData() {
        let refDate = Date()
        let todayIncome = incomeService.summarize(orders: allOrders, period: .day, referenceDate: refDate)
        let weekIncome = incomeService.summarize(orders: allOrders, period: .week, referenceDate: refDate)
        let monthIncome = incomeService.summarize(orders: allOrders, period: .month, referenceDate: refDate)
        let periodIncome: IncomeSummary
        switch currentPeriod {
        case .day:
            periodIncome = todayIncome
        case .week:
            periodIncome = weekIncome
        case .month:
            periodIncome = monthIncome
        }
        
        todaySum = todayIncome.sales
        weekSum = weekIncome.sales
        monthSum = monthIncome.sales
        
        let expenses = opexService.summarize(expenses: allExpenses, period: currentPeriod, referenceDate: refDate)
        monthExpenses = expenses.total
        monthProfit = financeService.computeNetProfit(sales: periodIncome.sales, opex: expenses.total)
        
        cashBalance = periodIncome.cash
        cardBalance = periodIncome.card
        
        lastIncome = periodIncome.last
        lastExpense = expenses.last
    }

}
