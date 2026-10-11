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
}

// MARK: - ABC Report DTO

// swiftlint:disable identifier_name
// a/b/c are standard ABC-analysis bucket names (Pareto 80/95/100)
enum ABCBucket: String {
    case a
    case b
    case c
}
// swiftlint:enable identifier_name

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

    init(
        database: DomainDB = DomainDatabaseService.shared,
        incomeService: IncomeAggregationServiceProtocol = IncomeAggregationService(),
        opexService: OpexAggregationServiceProtocol = OpexAggregationService(),
        financeService: FinanceAggregationServiceProtocol = FinanceAggregationService()
    ) {
        self.database = database
        self.incomeService = incomeService
        self.opexService = opexService
        self.financeService = financeService
    }

    // MARK: - P&L

    func fetchPLReport(period: DashboardPeriod, referenceDate: Date) async -> PLReport {
        let range = period.interval(for: referenceDate)
        let (orders, expenses) = await fetchBaseData(from: range.start, to: range.end)
        let income = incomeService.summarize(
            orders: orders, period: period, referenceDate: referenceDate)
        let opex = opexService.summarize(
            expenses: expenses, period: period, referenceDate: referenceDate)
        let profit = financeService.summarize(income: income, opex: opex)
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
            expensesCount: opex.count
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
            let label = Self.trendLabel(
                for: periodicity,
                startDate: window.start,
                endDate: window.end,
                index: index
            )
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
        async let orders = database.fetchOrders()
        async let expenses = database.fetchOpexExpenses()
        return await (orders, expenses)
    }

    private func fetchProductsOfOrders(from: Date, to: Date) async -> [OrderItemModel] {
        let safeFrom = max(Self.firestoreSafePast, Date.distantPast)
        return await database.fetchProductsOfOrders(
            from: safeFrom,
            to: Date.distantFuture
        )
    }

    // MARK: - ABC Bucketing (internal for testability)

    func buildABCRows(
        productsOfOrders: [OrderItemModel],
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
            accum.sales += item.totalSale
            accum.cogs += item.totalCost
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
            if i == 0 {
                // The top contributor is always bucket A, even if its share alone
                // reaches 100 % (single-item edge case of ABC analysis).
                bucket = .a
            } else {
                switch cumulative {
                case ..<80: bucket = .a
                case 80..<95: bucket = .b
                default: bucket = .c
                }
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

    private enum SharedFormatters {
        static let day: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("dMMM")
            return formatter
        }()

        private static let weekDayOnly: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("d")
            return formatter
        }()

        private static let weekMonthOnly: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("MMM")
            return formatter
        }()

        private static let weekYear: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("yy")
            return formatter
        }()

        static func weekLabel(start: Date, end: Date) -> String {
            let yyStr = weekYear.string(from: end)
            let sameMonth = Calendar.current.isDate(start, equalTo: end, toGranularity: .month)
            let sameYear = Calendar.current.isDate(start, equalTo: end, toGranularity: .year)
            let dayS = weekDayOnly.string(from: start)
            let dayE = weekDayOnly.string(from: end)

            if sameMonth, sameYear {
                let mm = weekMonthOnly.string(from: end)
                return "\(dayS)–\(dayE) \(mm) \(yyStr)"
            } else if sameYear {
                let mS = weekMonthOnly.string(from: start)
                let mE = weekMonthOnly.string(from: end)
                return "\(dayS) \(mS) – \(dayE) \(mE) \(yyStr)"
            } else {
                let yS = weekYear.string(from: start)
                let mS = weekMonthOnly.string(from: start)
                let yE = yyStr
                let mE = weekMonthOnly.string(from: end)
                return "\(dayS) \(mS) \(yS) – \(dayE) \(mE) \(yE)"
            }
        }

        static let month: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("MMMyyyy")
            return formatter
        }()
    }

    private static func trendLabel(
        for periodicity: DashboardPeriod,
        startDate: Date,
        endDate: Date,
        index: Int
    ) -> String {
        switch periodicity {
        case .day:
            return SharedFormatters.day.string(from: startDate)
        case .week:
            return SharedFormatters.weekLabel(start: startDate, end: endDate)
        case .month:
            return SharedFormatters.month.string(from: startDate)
        }
    }
}
