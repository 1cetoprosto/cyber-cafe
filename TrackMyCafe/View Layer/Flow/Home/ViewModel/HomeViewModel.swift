import Foundation

final class HomeViewModel: HomeViewModelType {
    private let incomeService: IncomeAggregationServiceProtocol
    private let opexService: OpexAggregationServiceProtocol
    private let financeService: FinanceAggregationServiceProtocol
    private let database: DomainDB

    private var currentPeriod: DashboardPeriod = .month
    private var allOrders: [OrderModel] = []
    private var allExpenses: [OpexExpenseModel] = []
    private var dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]] = [:]

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
        financeService: FinanceAggregationServiceProtocol = FinanceAggregationService(),
        database: DomainDB = DomainDatabaseService.shared
    ) {
        self.incomeService = incomeService
        self.opexService = opexService
        self.financeService = financeService
        self.database = database
    }

    @MainActor
    func loadDashboard() async {
        dateToday = Date()

        async let orders = fetchOrders()
        async let costs = fetchExpenses()
        async let cashBalances = fetchDailyBalances(for: .cash, through: dateToday)
        async let cardBalances = fetchDailyBalances(for: .card, through: dateToday)

        allOrders = await orders
        allExpenses = await costs
        dailyBalancesByAccount[.cash] = await cashBalances
        dailyBalancesByAccount[.card] = await cardBalances

        recomputeForCurrentData()
    }

    func setPeriod(_ period: DashboardPeriod) {
        currentPeriod = period
        recomputeForCurrentData()
    }

    func recomputeForCurrentData() {
        let refDate = dateToday
        let todayIncome = incomeService.summarize(
            orders: allOrders,
            period: .day,
            referenceDate: refDate
        )
        let weekIncome = incomeService.summarize(
            orders: allOrders,
            period: .week,
            referenceDate: refDate
        )
        let monthIncome = incomeService.summarize(
            orders: allOrders,
            period: .month,
            referenceDate: refDate
        )
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

        let expenses = opexService.summarize(
            expenses: allExpenses,
            period: currentPeriod,
            referenceDate: refDate
        )
        monthExpenses = expenses.total
        monthProfit = financeService.computeNetProfit(sales: periodIncome.sales, opex: expenses.total)

        cashBalance = currentBalance(for: .cash, referenceDate: refDate)
        cardBalance = currentBalance(for: .card, referenceDate: refDate)

        lastIncome = periodIncome.last
        lastExpense = expenses.last
    }
}

private extension HomeViewModel {
    func fetchOrders() async -> [OrderModel] {
        await withCheckedContinuation { continuation in
            database.fetchOrders { models in
                continuation.resume(returning: models)
            }
        }
    }

    func fetchExpenses() async -> [OpexExpenseModel] {
        await withCheckedContinuation { continuation in
            database.fetchOpexExpenses { models in
                continuation.resume(returning: models)
            }
        }
    }

    func fetchDailyBalances(for account: PaymentAccount, through referenceDate: Date) async -> [DailyBalanceModel] {
        await withCheckedContinuation { continuation in
            database.fetchDailyBalances(forAccount: account, from: .distantPast, to: referenceDate) { balances in
                continuation.resume(returning: balances)
            }
        }
    }

    func currentBalance(for account: PaymentAccount, referenceDate: Date) -> Double {
        let normalizedReferenceDate = Calendar.current.startOfDay(for: referenceDate)
        return dailyBalancesByAccount[account]?
            .filter { Calendar.current.startOfDay(for: $0.date) <= normalizedReferenceDate }
            .last?
            .balance ?? 0
    }
}
