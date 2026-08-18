import Foundation

struct DashboardPeriodSales {
    let period: DashboardPeriod
    let sales: Double
    let ordersCount: Int
    let cashSales: Double
    let cardSales: Double
}

struct DashboardPeriodExpenses {
    let period: DashboardPeriod
    let opex: Double
    let itemsCount: Int
}

struct DashboardPeriodPL {
    let period: DashboardPeriod
    let sales: Double
    let cogs: Double
    let opex: Double
    let grossProfit: Double
    let netProfit: Double
    let grossMarginPercent: Double
    let ordersCount: Int
    let expensesCount: Int
}

struct DashboardBalances {
    let cash: Double
    let card: Double
}

struct DashboardProductRanking {
    let productId: String
    let productName: String
    let sales: Double
    let cogs: Double
    let grossProfit: Double
    let quantity: Double
}

struct DashboardSnapshot {
    let referenceDate: Date
    let currentPeriod: DashboardPeriod
    let plByPeriod: [DashboardPeriod: DashboardPeriodPL]
    let balances: DashboardBalances
    let lastOrdersInPeriod: [OrderModel]
    let lastExpensesInPeriod: [OpexExpenseModel]
    let bestProductInPeriod: DashboardProductRanking?
    let worstProductInPeriod: DashboardProductRanking?
}

protocol DomainDashboardFacadeProtocol {
    func makeSnapshot(
        currentPeriod: DashboardPeriod,
        referenceDate: Date,
        orders: [OrderModel],
        expenses: [OpexExpenseModel],
        productsOfOrders: [ProductOfOrderModel],
        dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]]
    ) -> DashboardSnapshot
}

final class DomainDashboardFacade: DomainDashboardFacadeProtocol {

    private let incomeService: IncomeAggregationServiceProtocol
    private let opexService: OpexAggregationServiceProtocol
    private let financeService: FinanceAggregationServiceProtocol

    init(
        incomeService: IncomeAggregationServiceProtocol = IncomeAggregationService(),
        opexService: OpexAggregationServiceProtocol = OpexAggregationService(),
        financeService: FinanceAggregationServiceProtocol = FinanceAggregationService()
    ) {
        self.incomeService = incomeService
        self.opexService = opexService
        self.financeService = financeService
    }

    func makeSnapshot(
        currentPeriod: DashboardPeriod,
        referenceDate: Date,
        orders: [OrderModel],
        expenses: [OpexExpenseModel],
        productsOfOrders: [ProductOfOrderModel],
        dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]]
    ) -> DashboardSnapshot {
        var plByPeriod: [DashboardPeriod: DashboardPeriodPL] = [:]
        var plCurrent: DashboardPeriodPL?
        var lastOrders: [OrderModel] = []
        var lastExpenses: [OpexExpenseModel] = []

        for period in [DashboardPeriod.day, .week, .month] {
            let income = incomeService.summarize(
                orders: orders,
                period: period,
                referenceDate: referenceDate
            )
            let opex = opexService.summarize(
                expenses: expenses,
                period: period,
                referenceDate: referenceDate
            )
            let profit = financeService.summarize(income: income, opex: opex)

            let pl = DashboardPeriodPL(
                period: period,
                sales: profit.sales,
                cogs: profit.cogs,
                opex: profit.opex,
                grossProfit: profit.grossProfit,
                netProfit: profit.netProfit,
                grossMarginPercent: profit.grossMarginPercent,
                ordersCount: income.count,
                expensesCount: opex.count
            )
            plByPeriod[period] = pl

            if period == currentPeriod {
                plCurrent = pl
                lastOrders = income.last
                lastExpenses = opex.last
            }
        }

        let interval = currentPeriod.interval(for: referenceDate)
        let ranking = buildProductRanking(
            productsOfOrders: productsOfOrders,
            interval: interval
        )
        let best = ranking.max { $0.grossProfit < $1.grossProfit }
        let worst = ranking.min { $0.grossProfit < $1.grossProfit }

        let balances = DashboardBalances(
            cash: latestBalance(
                for: .cash, dailyBalancesByAccount: dailyBalancesByAccount,
                referenceDate: referenceDate),
            card: latestBalance(
                for: .card, dailyBalancesByAccount: dailyBalancesByAccount,
                referenceDate: referenceDate)
        )

        return DashboardSnapshot(
            referenceDate: referenceDate,
            currentPeriod: currentPeriod,
            plByPeriod: plByPeriod,
            balances: balances,
            lastOrdersInPeriod: lastOrders,
            lastExpensesInPeriod: lastExpenses,
            bestProductInPeriod: best,
            worstProductInPeriod: worst
        )
    }
}

extension DomainDashboardFacade {

    fileprivate func buildProductRanking(
        productsOfOrders: [ProductOfOrderModel],
        interval: DateInterval
    ) -> [DashboardProductRanking] {
        let filtered = productsOfOrders.filter { interval.contains($0.date) }
        var byProduct: [String: (name: String, sales: Double, cogs: Double, qty: Double)] = [:]
        for item in filtered {
            let key = item.productId
            var accum = byProduct[key] ?? (name: item.name, sales: 0, cogs: 0, qty: 0)
            accum.sales += item.sum
            accum.cogs += item.costSum
            accum.qty += Double(item.quantity)
            accum.name = item.name
            byProduct[key] = accum
        }
        return byProduct.map { (key, value) in
            DashboardProductRanking(
                productId: key,
                productName: value.name,
                sales: value.sales,
                cogs: value.cogs,
                grossProfit: value.sales - value.cogs,
                quantity: value.qty
            )
        }
    }

    fileprivate func latestBalance(
        for account: PaymentAccount,
        dailyBalancesByAccount: [PaymentAccount: [DailyBalanceModel]],
        referenceDate: Date
    ) -> Double {
        let normalizedReferenceDate = Calendar.current.startOfDay(for: referenceDate)
        return dailyBalancesByAccount[account]?
            .filter { Calendar.current.startOfDay(for: $0.date) <= normalizedReferenceDate }
            .last?
            .balance ?? 0
    }
}
