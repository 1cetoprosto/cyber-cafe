import Foundation

final class HomeViewModel: HomeViewModelType {
    private let facade: DomainDashboardFacadeProtocol
    private let database: DomainDB

    private var currentPeriod: DashboardPeriod = .month
    private var allOrders: [OrderModel] = []
    private var allExpenses: [OpexExpenseModel] = []
    private var allProductsOfOrders: [OrderItemModel] = []
    private var dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]] = [:]
    private var snapshot: DashboardSnapshot?

    private(set) var todaySum: Double = 0
    private(set) var weekSum: Double = 0
    private(set) var monthSum: Double = 0
    private(set) var periodExpenses: Double = 0
    private(set) var periodProfit: Double = 0
    private(set) var previousPeriodProfit: Double?
    private(set) var periodProfitDeltaPercent: Double?
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

        // Same-length windows (month = MTD vs same days last month) so Δ% is meaningful mid-month.
        if let windows = currentPeriod.comparisonIntervals(for: refDate) {
            let currentComparable = facade.makePeriodPL(
                period: currentPeriod,
                intervalStart: windows.currentStart,
                intervalEnd: windows.currentEnd,
                orders: allOrders,
                expenses: allExpenses
            )
            let previousComparable = facade.makePeriodPL(
                period: currentPeriod,
                intervalStart: windows.previousStart,
                intervalEnd: windows.previousEnd,
                orders: allOrders,
                expenses: allExpenses
            )
            previousPeriodProfit = previousComparable.netProfit
            periodProfitDeltaPercent = Self.deltaPercent(
                current: currentComparable.netProfit,
                previous: previousComparable.netProfit
            )
        } else {
            previousPeriodProfit = nil
            periodProfitDeltaPercent = nil
        }

        cashBalance = snapshot?.balances.cash ?? 0
        cardBalance = snapshot?.balances.card ?? 0

        lastIncome = snapshot?.lastOrdersInPeriod ?? []
        lastExpense = snapshot?.lastExpensesInPeriod ?? []
    }

    /// Percent change vs previous period. `nil` when previous is zero/unavailable.
    static func deltaPercent(current: Double, previous: Double) -> Double? {
        guard previous != 0 else { return nil }
        return ((current - previous) / abs(previous)) * 100
    }
}

extension HomeViewModel {
    fileprivate func fetchOrders() async -> [OrderModel] {
        await database.fetchOrders()
    }

    fileprivate func fetchExpenses() async -> [OpexExpenseModel] {
        await database.fetchOpexExpenses()
    }

    fileprivate func fetchAllProductsOfOrders() async -> [OrderItemModel] {
        await database.fetchProductsOfOrders(
            from: Self.firestoreSafePast, to: Date()
        )
    }

    func fetchDailyBalances(for account: PaymentAccount, through referenceDate: Date) async
        -> [DailyBalanceModel]
    {
        await database.fetchDailyBalances(
            forAccount: account,
            from: Self.firestoreSafePast,
            to: referenceDate
        )
    }

    private static let firestoreSafePast: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date.distantPast
    }()
}
