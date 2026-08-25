import Foundation
import os.log

// MARK: - P&L Report DTO

struct PLReport {
    let period: DashboardPeriod
    let referenceDate: Date
    let range: DateInterval
    let sales: Double
    let cashSales: Double
    let cardSales: Double
    let cogs: Double
    let opex: Double
    let grossProfit: Double
    let netProfit: Double
    let grossMarginPercent: Double
    let ordersCount: Int
    let expensesCount: Int
    let manualSpending: Double
    let spendingResult: Double
}

// MARK: - ABC Report DTO

enum ABCBucket: String {
    case a
    case b
    case c
}

enum ABCRankingKey {
    case sales
    case grossProfit
}

struct ABCProductRow {
    let productId: String
    let productName: String
    let sales: Double
    let cogs: Double
    let grossProfit: Double
    let quantity: Double
    let sharePercent: Double
    let cumulativePercent: Double
    let bucket: ABCBucket
}

struct ABCReport {
    let period: DashboardPeriod
    let referenceDate: Date
    let range: DateInterval
    let rankingKey: ABCRankingKey
    let totalSales: Double
    let totalGrossProfit: Double
    let rows: [ABCProductRow]
    let countsByBucket: [ABCBucket: Int]
}

// MARK: - Trends Report DTO

struct TrendPoint {
    let label: String
    let startDate: Date
    let endDate: Date
    let sales: Double
    let cogs: Double
    let opex: Double
    let netProfit: Double
}

struct TrendsReport {
    let periodicity: DashboardPeriod
    let referenceDate: Date
    let points: [TrendPoint]
}

// MARK: - Finance/Reporting Facade Protocol

protocol FinanceReportingServiceProtocol {
    func fetchPLReport(
        period: DashboardPeriod,
        referenceDate: Date
    ) async -> PLReport

    func fetchABCReport(
        period: DashboardPeriod,
        referenceDate: Date,
        rankingKey: ABCRankingKey
    ) async -> ABCReport

    func fetchTrendsReport(
        periodicity: DashboardPeriod,
        periodsBack: Int,
        referenceDate: Date
    ) async -> TrendsReport
}

// MARK: - Finance/Reporting Facade Implementation

final class FinanceReportingService: FinanceReportingServiceProtocol, Loggable {

    private let database: DomainDB
    private let incomeService: IncomeAggregationServiceProtocol
    private let opexService: OpexAggregationServiceProtocol
    private let financeService: FinanceAggregationServiceProtocol
    private let manualMovementService: ManualMovementServiceProtocol

    init(
        database: DomainDB = DomainDatabaseService.shared,
        incomeService: IncomeAggregationServiceProtocol = IncomeAggregationService(),
        opexService: OpexAggregationServiceProtocol = OpexAggregationService(),
        financeService: FinanceAggregationServiceProtocol = FinanceAggregationService(),
        manualMovementService: ManualMovementServiceProtocol = DomainManualMovementService()
    ) {
        self.database = database
        self.incomeService = incomeService
        self.opexService = opexService
        self.financeService = financeService
        self.manualMovementService = manualMovementService
    }

    // MARK: - P&L

    func fetchPLReport(period: DashboardPeriod, referenceDate: Date) async -> PLReport {
        let range = period.interval(for: referenceDate)
        let (orders, expenses, manualOps) = await fetchPLBaseData(from: range.start, to: range.end)
        let income = incomeService.summarize(
            orders: orders, period: period, referenceDate: referenceDate)
        let opex = opexService.summarize(
            expenses: expenses, period: period, referenceDate: referenceDate)
        let profit = financeService.summarize(income: income, opex: opex)
        let manualSpending = aggregateManualSpending(
            operations: manualOps, intervalStart: range.start, intervalEnd: range.end)
        let spendingResult = manualSpending - profit.sales
        return PLReport(
            period: period,
            referenceDate: referenceDate,
            range: range,
            sales: profit.sales,
            cashSales: income.cash,
            cardSales: income.card,
            cogs: profit.cogs,
            opex: profit.opex,
            grossProfit: profit.grossProfit,
            netProfit: profit.netProfit,
            grossMarginPercent: profit.grossMarginPercent,
            ordersCount: income.count,
            expensesCount: opex.count,
            manualSpending: manualSpending,
            spendingResult: spendingResult
        )
    }

    // MARK: - ABC

    func fetchABCReport(
        period: DashboardPeriod,
        referenceDate: Date,
        rankingKey: ABCRankingKey
    ) async -> ABCReport {
        let range = period.interval(for: referenceDate)
        let productsOfOrders = await fetchProductsOfOrders(from: range.start, to: range.end)
        let rows = buildABCRows(
            productsOfOrders: productsOfOrders, range: range, rankingKey: rankingKey)
        let totalSales = rows.reduce(0) { $0 + $1.sales }
        let totalGross = rows.reduce(0) { $0 + $1.grossProfit }
        var counts: [ABCBucket: Int] = [.a: 0, .b: 0, .c: 0]
        for row in rows {
            counts[row.bucket, default: 0] += 1
        }
        return ABCReport(
            period: period,
            referenceDate: referenceDate,
            range: range,
            rankingKey: rankingKey,
            totalSales: totalSales,
            totalGrossProfit: totalGross,
            rows: rows,
            countsByBucket: counts
        )
    }

    // MARK: - Trends

    func fetchTrendsReport(
        periodicity: DashboardPeriod,
        periodsBack: Int,
        referenceDate: Date
    ) async -> TrendsReport {
        let windows = buildTrendWindows(
            periodicity: periodicity,
            periodsBack: periodsBack,
            referenceDate: referenceDate
        )
        guard let firstStart = windows.first?.start, let lastEnd = windows.last?.end else {
            return TrendsReport(periodicity: periodicity, referenceDate: referenceDate, points: [])
        }
        let (orders, expenses) = await fetchBaseData(from: firstStart, to: lastEnd)
        let df = DateFormatter()
        df.locale = Locale(identifier: "uk_UA")
        df.dateFormat = "dd.MM.yyyy HH:mm"
        logger.info(
            "Trends fetch periodicity=\(String(describing: periodicity)) periodsBack=\(periodsBack)"
                + " windows.count=\(windows.count) orders=\(orders.count) expenses=\(expenses.count)"
        )
        var points: [TrendPoint] = []
        for (index, window) in windows.enumerated() {
            let label = Self.trendLabel(for: periodicity, date: window.start, index: index)
            let income = incomeService.summarize(
                orders: orders,
                intervalStart: window.start,
                intervalEnd: window.end)
            let opex = opexService.summarize(
                expenses: expenses,
                intervalStart: window.start,
                intervalEnd: window.end)
            let profit = financeService.summarize(income: income, opex: opex)
            let point = TrendPoint(
                label: label,
                startDate: window.start,
                endDate: window.end,
                sales: profit.sales,
                cogs: profit.cogs,
                opex: profit.opex,
                netProfit: profit.netProfit
            )
            logger.info(
                "  → [\(index)] \(label)"
                    + " [\(df.string(from: window.start)) – \(df.string(from: window.end))]"
                    + " ordersInWindow=\(income.count) expensesInWindow=\(opex.count)"
                    + " sales=\(String(format: "%.0f", profit.sales))"
                    + " cogs=\(String(format: "%.0f", profit.cogs))"
                    + " opex=\(String(format: "%.0f", profit.opex))"
                    + " net=\(String(format: "%.0f", profit.netProfit))"
            )
            points.append(point)
        }
        let totalSales = points.reduce(0) { $0 + $1.sales }
        let totalCogs = points.reduce(0) { $0 + $1.cogs }
        let totalOpex = points.reduce(0) { $0 + $1.opex }
        let totalNet = points.reduce(0) { $0 + $1.netProfit }
        logger.info(
            "Trends fetch TOTAL sales=\(String(format: "%.0f", totalSales))"
                + " cogs=\(String(format: "%.0f", totalCogs))"
                + " opex=\(String(format: "%.0f", totalOpex))"
                + " net=\(String(format: "%.0f", totalNet))"
        )
        return TrendsReport(periodicity: periodicity, referenceDate: referenceDate, points: points)
    }

    // MARK: - Private (Data Fetch)

    private func fetchPLBaseData(from: Date, to: Date) async -> (
        orders: [OrderModel], expenses: [OpexExpenseModel], manualOps: [ManualMovementOperation]
    ) {
        let (baseOrders, baseExpenses) = await fetchBaseData(from: from, to: to)
        let manual = await manualMovementService.fetchOperations()
        return (baseOrders, baseExpenses, manual)
    }

    private func aggregateManualSpending(
        operations: [ManualMovementOperation], intervalStart: Date, intervalEnd: Date
    ) -> Double {
        operations.reduce(0) { total, op in
            guard op.date >= intervalStart && op.date <= intervalEnd else { return total }
            switch op.kind {
            case .withdrawal:
                return total + abs(op.amount)
            case .adjustment where op.amount < 0:
                return total + abs(op.amount)
            default:
                return total
            }
        }
    }

    private static let firestoreSafePast: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date.distantPast
    }()

    private func fetchBaseData(from: Date, to: Date) async -> (
        orders: [OrderModel], expenses: [OpexExpenseModel]
    ) {
        _ = (from, to)
        return await withCheckedContinuation { continuation in
            var orders: [OrderModel] = []
            var expenses: [OpexExpenseModel] = []
            let group = DispatchGroup()
            group.enter()
            database.fetchOrders { models in
                orders = models
                group.leave()
            }
            group.enter()
            database.fetchOpexExpenses { models in
                expenses = models
                group.leave()
            }
            group.notify(queue: .main) {
                continuation.resume(returning: (orders, expenses))
            }
        }
    }

    private func fetchProductsOfOrders(from: Date, to: Date) async -> [ProductOfOrderModel] {
        let safeFrom = max(Self.firestoreSafePast, Date.distantPast)
        return await withCheckedContinuation { continuation in
            database.fetchProductsOfOrders(
                from: safeFrom,
                to: Date.distantFuture
            ) { models in
                continuation.resume(returning: models)
            }
        }
    }

    // MARK: - ABC Bucketing (internal for testability)

    func buildABCRows(
        productsOfOrders: [ProductOfOrderModel],
        range: DateInterval,
        rankingKey: ABCRankingKey
    ) -> [ABCProductRow] {
        let filtered = productsOfOrders.filter { range.contains($0.date) }
        var byProduct: [String: (name: String, sales: Double, cogs: Double, qty: Double)] = [:]
        for item in filtered {
            let key: String = {
                let pid = item.productId.trimmingCharacters(in: .whitespacesAndNewlines)
                if pid.isEmpty {
                    return "name::" + item.name
                }
                return pid
            }()
            var accum = byProduct[key] ?? (name: item.name, sales: 0, cogs: 0, qty: 0)
            accum.sales += item.sum
            accum.cogs += item.costSum
            accum.qty += Double(item.quantity)
            accum.name = item.name
            byProduct[key] = accum
        }
        let ranking = byProduct.map { (key, value) -> ABCProductRow in
            let gross = value.sales - value.cogs
            return ABCProductRow(
                productId: key.hasPrefix("name::") ? "" : key,
                productName: value.name,
                sales: value.sales,
                cogs: value.cogs,
                grossProfit: gross,
                quantity: value.qty,
                sharePercent: 0,
                cumulativePercent: 0,
                bucket: .c
            )
        }
        let totalSales = ranking.reduce(0) { $0 + $1.sales }
        var sorted = ranking.sorted { lhs, rhs in
            switch rankingKey {
            case .sales: return lhs.sales > rhs.sales
            case .grossProfit: return lhs.grossProfit > rhs.grossProfit
            }
        }
        var cumulative = 0.0
        for i in 0..<sorted.count {
            let share = (totalSales == 0) ? 0 : (sorted[i].sales / totalSales) * 100
            cumulative += share
            let bucket: ABCBucket
            switch cumulative {
            case ..<80: bucket = .a
            case 80..<95: bucket = .b
            default: bucket = .c
            }
            sorted[i] = ABCProductRow(
                productId: sorted[i].productId,
                productName: sorted[i].productName,
                sales: sorted[i].sales,
                cogs: sorted[i].cogs,
                grossProfit: sorted[i].grossProfit,
                quantity: sorted[i].quantity,
                sharePercent: share,
                cumulativePercent: cumulative,
                bucket: bucket
            )
        }
        return sorted
    }

    // MARK: - Trends Windows (internal for testability)

    func buildTrendWindows(
        periodicity: DashboardPeriod,
        periodsBack: Int,
        referenceDate: Date
    ) -> [DateInterval] {
        let calendar = Calendar.current
        var windows: [DateInterval] = []
        for offset in stride(from: (periodsBack - 1), through: 0, by: -1) {
            guard
                let shifted = shiftedBack(
                    referenceDate: referenceDate, offset: offset, periodicity: periodicity,
                    calendar: calendar)
            else { continue }
            windows.append(periodicity.interval(for: shifted, calendar: calendar))
        }
        return windows
    }

    private func shiftedBack(
        referenceDate: Date, offset: Int, periodicity: DashboardPeriod, calendar: Calendar
    ) -> Date? {
        switch periodicity {
        case .day: return calendar.date(byAdding: .day, value: -offset, to: referenceDate)
        case .week: return calendar.date(byAdding: .weekOfYear, value: -offset, to: referenceDate)
        case .month: return calendar.date(byAdding: .month, value: -offset, to: referenceDate)
        }
    }

    private static func trendLabel(for periodicity: DashboardPeriod, date: Date, index: Int)
        -> String
    {
        let formatter = DateFormatter()
        switch periodicity {
        case .day:
            formatter.dateFormat = "d MMM"
        case .week:
            formatter.dateFormat = "'W'w yy"
        case .month:
            formatter.dateFormat = "LLL yy"
        }
        return formatter.string(from: date)
    }
}
