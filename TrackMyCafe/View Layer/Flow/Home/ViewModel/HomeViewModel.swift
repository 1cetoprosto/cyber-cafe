import Foundation

final class HomeViewModel: HomeViewModelType {
    private let facade: DomainDashboardFacadeProtocol
    private let database: DomainDB

    private var currentPeriod: DashboardPeriod = .month
    private var allOrders: [OrderModel] = []
    private var allExpenses: [OpexExpenseModel] = []
    private var allProductsOfOrders: [ProductOfOrderModel] = []
    private var dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]] = [:]
    private var snapshot: DashboardSnapshot?

    private(set) var todaySum: Double = 0
    private(set) var weekSum: Double = 0
    private(set) var monthSum: Double = 0
    private(set) var periodExpenses: Double = 0
    private(set) var periodProfit: Double = 0
    private(set) var dateToday: Date = Date()
    private(set) var cashBalance: Double = 0
    private(set) var cardBalance: Double = 0

    private(set) var lastIncome: [OrderModel] = []
    private(set) var lastExpense: [OpexExpenseModel] = []

    init(
        facade: DomainDashboardFacadeProtocol = DomainDashboardFacade(),
        database: DomainDB = DomainDatabaseService.shared
    ) {
        self.facade = facade
        self.database = database
    }

    @MainActor
    func loadDashboard() async {
        dateToday = Date()

        async let orders = fetchOrders()
        async let costs = fetchExpenses()
        async let productsOfOrders = fetchAllProductsOfOrders()
        async let cashBalances = fetchDailyBalances(for: .cash, through: dateToday)
        async let cardBalances = fetchDailyBalances(for: .card, through: dateToday)

        allOrders = await orders
        allExpenses = await costs
        allProductsOfOrders = await productsOfOrders
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
        snapshot = facade.makeSnapshot(
            currentPeriod: currentPeriod,
            referenceDate: refDate,
            orders: allOrders,
            expenses: allExpenses,
            productsOfOrders: allProductsOfOrders,
            dailyBalancesByAccount: dailyBalancesByAccount
        )

        let dayPL = snapshot?.plByPeriod[.day]
        let weekPL = snapshot?.plByPeriod[.week]
        let monthPL = snapshot?.plByPeriod[.month]
        let currentPL = snapshot?.plByPeriod[currentPeriod]

        todaySum = dayPL?.sales ?? 0
        weekSum = weekPL?.sales ?? 0
        monthSum = monthPL?.sales ?? 0

        periodExpenses = currentPL?.opex ?? 0
        periodProfit = currentPL?.netProfit ?? 0

        cashBalance = snapshot?.balances.cash ?? 0
        cardBalance = snapshot?.balances.card ?? 0

        lastIncome = snapshot?.lastOrdersInPeriod ?? []
        lastExpense = snapshot?.lastExpensesInPeriod ?? []
    }
}

extension HomeViewModel {
    fileprivate func fetchOrders() async -> [OrderModel] {
        await withCheckedContinuation { continuation in
            database.fetchOrders { models in
                continuation.resume(returning: models)
            }
        }
    }

    fileprivate func fetchExpenses() async -> [OpexExpenseModel] {
        await withCheckedContinuation { continuation in
            database.fetchOpexExpenses { models in
                continuation.resume(returning: models)
            }
        }
    }

    fileprivate func fetchAllProductsOfOrders() async -> [ProductOfOrderModel] {
        await withCheckedContinuation { continuation in
            database.fetchProductsOfOrders(from: .distantPast, to: Date()) { models in
                continuation.resume(returning: models)
            }
        }
    }

    fileprivate func fetchDailyBalances(for account: PaymentAccount, through referenceDate: Date)
        async -> [DailyBalanceModel]
    {
        await withCheckedContinuation { continuation in
            database.fetchDailyBalances(forAccount: account, from: .distantPast, to: referenceDate)
            { balances in
                continuation.resume(returning: balances)
            }
        }
    }
}
