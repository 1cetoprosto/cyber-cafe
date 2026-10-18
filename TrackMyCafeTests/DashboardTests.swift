//
//  DashboardTests.swift
//  TrackMyCafeTests
//
//  Dashboard period boundaries and the DomainDashboardFacade snapshot builder.
//

import XCTest

@testable import TrackMyCafe_Dev

final class DashboardTests: XCTestCase {
    // MARK: - DashboardPeriod interval boundaries

    func testDashboardPeriod_dayInterval_matchesCalendarDay() {
        let ref = makeDate(year: 2026, month: 6, day: 22)
        let interval = DashboardPeriod.day.interval(for: ref)
        let cal = Calendar.current
        XCTAssertTrue(cal.isDate(interval.start, inSameDayAs: ref))
        XCTAssertEqual(cal.component(.hour, from: interval.start), 0)
        XCTAssertEqual(cal.component(.minute, from: interval.start), 0)
        XCTAssertTrue(cal.isDate(interval.end, inSameDayAs: ref))
        XCTAssertEqual(cal.component(.hour, from: interval.end), 23)
        XCTAssertEqual(cal.component(.minute, from: interval.end), 59)
    }

    func testDashboardPeriod_monthInterval_rollsCorrectMonthRange() {
        let ref = makeDate(year: 2026, month: 6, day: 15)
        let interval = DashboardPeriod.month.interval(for: ref)
        let cal = Calendar.current
        let startComps = cal.dateComponents([.year, .month, .day], from: interval.start)
        XCTAssertEqual(startComps.year, 2026)
        XCTAssertEqual(startComps.month, 6)
        XCTAssertEqual(startComps.day, 1)
        let endComps = cal.dateComponents([.year, .month, .day], from: interval.end)
        XCTAssertEqual(endComps.year, 2026)
        XCTAssertEqual(endComps.month, 6)
        XCTAssertEqual(endComps.day, 30)
    }

    func testDashboardPeriod_weekInterval_coversSevenDays() {
        let ref = makeDate(year: 2026, month: 6, day: 22)
        let interval = DashboardPeriod.week.interval(for: ref)
        let dayCount =
            Calendar.current.dateComponents(
                [.day], from: interval.start, to: interval.end
            ).day ?? -1
        XCTAssertGreaterThanOrEqual(dayCount, 6)
        XCTAssertLessThanOrEqual(dayCount, 7)
    }

    // MARK: - DomainDashboardFacade

    func testDomainDashboardFacade_basicPLComputedCorrectly() {
        let facade = DomainDashboardFacade()
        let refDate = makeDate(year: 2026, month: 8, day: 15)
        let orders: [OrderModel] = [
            OrderModel(
                id: "o1", date: refDate, type: "Hall", sum: 200, cash: 200, card: 0, totalCost: 80,
                note: ""),
            OrderModel(
                id: "o2", date: refDate.addingTimeInterval(-600), type: "Hall", sum: 100, cash: 0,
                card: 100, totalCost: 40, note: ""),
        ]
        let expenses: [OpexExpenseModel] = [
            OpexExpenseModel(
                id: "e1", date: refDate, categoryId: "rent", amount: 50, paymentAccount: .cash,
                note: "")
        ]

        let snapshot = facade.makeSnapshot(
            currentPeriod: .day,
            referenceDate: refDate,
            orders: orders,
            expenses: expenses,
            productsOfOrders: [],
            dailyBalancesByAccount: [:]
        )

        let day = try! XCTUnwrap(snapshot.plByPeriod[.day])
        XCTAssertEqual(day.sales, 300, accuracy: 0.0001)
        XCTAssertEqual(day.cogs, 120, accuracy: 0.0001)
        XCTAssertEqual(day.opex, 50, accuracy: 0.0001)
        XCTAssertEqual(day.grossProfit, 180, accuracy: 0.0001)
        XCTAssertEqual(day.netProfit, 130, accuracy: 0.0001)
        XCTAssertEqual(day.grossMarginPercent, 60.0, accuracy: 0.01)
        XCTAssertEqual(day.ordersCount, 2)
        XCTAssertEqual(day.expensesCount, 1)
    }

    func testDomainDashboardFacade_threePeriodsAreIndependent() {
        let facade = DomainDashboardFacade()
        let refDate = makeDate(year: 2026, month: 8, day: 15)
        let sameDay = makeDate(year: 2026, month: 8, day: 15)
        let anotherDaySameWeek = makeDate(year: 2026, month: 8, day: 10)
        let sameMonthDifferentWeek = makeDate(year: 2026, month: 8, day: 1)
        let differentMonth = makeDate(year: 2026, month: 7, day: 15)

        let orders: [OrderModel] = [
            OrderModel(
                id: "d", date: sameDay, type: "H", sum: 100, cash: 100, card: 0, totalCost: 0,
                note: ""),
            OrderModel(
                id: "w", date: anotherDaySameWeek, type: "H", sum: 200, cash: 200, card: 0,
                totalCost: 0, note: ""),
            OrderModel(
                id: "m", date: sameMonthDifferentWeek, type: "H", sum: 400, cash: 400, card: 0,
                totalCost: 0, note: ""),
            OrderModel(
                id: "x", date: differentMonth, type: "H", sum: 999, cash: 999, card: 0,
                totalCost: 0, note: ""),
        ]

        let snapshot = facade.makeSnapshot(
            currentPeriod: .week,
            referenceDate: refDate,
            orders: orders,
            expenses: [],
            productsOfOrders: [],
            dailyBalancesByAccount: [:]
        )

        XCTAssertEqual(snapshot.plByPeriod[.day]?.sales ?? 0, 100, accuracy: 0.01)
        XCTAssertEqual(snapshot.plByPeriod[.week]?.sales ?? 0, 300, accuracy: 0.01)
        XCTAssertEqual(snapshot.plByPeriod[.month]?.sales ?? 0, 700, accuracy: 0.01)
    }

    func testDomainDashboardFacade_periodSelector_switchesLastListsToCorrectPeriod() {
        let facade = DomainDashboardFacade()
        let day1 = makeDate(year: 2026, month: 8, day: 15)
        let day7 = makeDate(year: 2026, month: 8, day: 13)
        let day30 = makeDate(year: 2026, month: 8, day: 1)
        let orderToday = OrderModel(
            id: "today", date: day1, type: "H", sum: 100, cash: 100, card: 0, totalCost: 0, note: ""
        )
        let orderWeekOnly = OrderModel(
            id: "week", date: day7, type: "H", sum: 50, cash: 50, card: 0, totalCost: 0, note: "")
        let orderMonthOnly = OrderModel(
            id: "month", date: day30, type: "H", sum: 20, cash: 20, card: 0, totalCost: 0, note: "")

        let ref = day1
        let snapshotDay = facade.makeSnapshot(
            currentPeriod: .day,
            referenceDate: ref,
            orders: [orderToday, orderWeekOnly, orderMonthOnly],
            expenses: [],
            productsOfOrders: [],
            dailyBalancesByAccount: [:]
        )
        let snapshotWeek = facade.makeSnapshot(
            currentPeriod: .week,
            referenceDate: ref,
            orders: [orderToday, orderWeekOnly, orderMonthOnly],
            expenses: [],
            productsOfOrders: [],
            dailyBalancesByAccount: [:]
        )
        let snapshotMonth = facade.makeSnapshot(
            currentPeriod: .month,
            referenceDate: ref,
            orders: [orderToday, orderWeekOnly, orderMonthOnly],
            expenses: [],
            productsOfOrders: [],
            dailyBalancesByAccount: [:]
        )

        XCTAssertEqual(snapshotDay.lastOrdersInPeriod.count, 1)
        XCTAssertEqual(snapshotDay.lastOrdersInPeriod.first?.id, "today")
        XCTAssertEqual(snapshotWeek.lastOrdersInPeriod.count, 2)
        XCTAssertEqual(snapshotMonth.lastOrdersInPeriod.count, 3)
    }

    func testDomainDashboardFacade_bestAndWorstProduct() {
        let facade = DomainDashboardFacade()
        let ref = makeDate(year: 2026, month: 8, day: 15)
        let inPeriod = ref.addingTimeInterval(3600)
        let products: [OrderItemModel] = [
            OrderItemModel(
                id: "p1", productId: "a", name: "Espresso", orderId: "o", date: inPeriod,
                quantity: 5, salePrice: 30, costPrice: 5),
            OrderItemModel(
                id: "p2", productId: "b", name: "Tea", orderId: "o", date: inPeriod,
                quantity: 2, salePrice: 20, costPrice: 18),
        ]

        let snapshot = facade.makeSnapshot(
            currentPeriod: .day,
            referenceDate: ref,
            orders: [],
            expenses: [],
            productsOfOrders: products,
            dailyBalancesByAccount: [:]
        )

        XCTAssertEqual(snapshot.bestProductInPeriod?.productId, "a")
        XCTAssertEqual(snapshot.bestProductInPeriod?.grossProfit ?? 0, 125, accuracy: 0.0001)
        XCTAssertEqual(snapshot.worstProductInPeriod?.productId, "b")
        XCTAssertEqual(snapshot.worstProductInPeriod?.grossProfit ?? 0, 4, accuracy: 0.0001)
    }

    func testDomainDashboardFacade_productRankingOutsidePeriodIgnored() {
        let facade = DomainDashboardFacade()
        let ref = makeDate(year: 2026, month: 8, day: 15)
        let inside = ref.addingTimeInterval(3600)
        let outside = makeDate(year: 2026, month: 8, day: 1)
        let products: [OrderItemModel] = [
            OrderItemModel(
                id: "p1", productId: "a", name: "X", orderId: "o1", date: inside,
                quantity: 1, salePrice: 10, costPrice: 1),
            OrderItemModel(
                id: "p2", productId: "b", name: "Y", orderId: "o2", date: outside,
                quantity: 1, salePrice: 99, costPrice: 1),
        ]

        let snapshot = facade.makeSnapshot(
            currentPeriod: .day,
            referenceDate: ref,
            orders: [],
            expenses: [],
            productsOfOrders: products,
            dailyBalancesByAccount: [:]
        )

        XCTAssertEqual(snapshot.bestProductInPeriod?.productId, "a")
        XCTAssertEqual(snapshot.worstProductInPeriod?.productId, "a")
    }

    func testDomainDashboardFacade_balancesPicksLatestForReferenceDate() {
        let facade = DomainDashboardFacade()
        let ref = makeDate(year: 2026, month: 8, day: 15)
        let balances: [PaymentAccount: [DailyBalanceModel]] = [
            .cash: [
                DailyBalanceModel(
                    date: makeDate(year: 2026, month: 8, day: 10), account: .cash, balance: 50,
                    delta: 0),
                DailyBalanceModel(
                    date: makeDate(year: 2026, month: 8, day: 14), account: .cash, balance: 200,
                    delta: 0),
            ],
            .card: [
                DailyBalanceModel(
                    date: makeDate(year: 2026, month: 8, day: 12), account: .card, balance: 300,
                    delta: 0)
            ],
        ]

        let snapshot = facade.makeSnapshot(
            currentPeriod: .day,
            referenceDate: ref,
            orders: [],
            expenses: [],
            productsOfOrders: [],
            dailyBalancesByAccount: balances
        )

        XCTAssertEqual(snapshot.balances.cash, 200, accuracy: 0.0001)
        XCTAssertEqual(snapshot.balances.card, 300, accuracy: 0.0001)
    }
}
