//
//  ReportsTests.swift
//  TrackMyCafeTests
//
//  Reports Hub: ABC analysis rows and trend windows.
//

import XCTest

@testable import TrackMyCafe_Dev

final class ReportsTests: XCTestCase {
    // MARK: - Finance/Reporting Facade #145

    func testFinanceReporting_abcBuckets_bySales_80_95_100() {
        let service = FinanceReportingService()
        let aug15 = makeDate(year: 2026, month: 8, day: 15)
        let range = DashboardPeriod.month.interval(for: aug15)

        // 4 products with sales 60 / 20 / 15 / 5 (total 100)
        let p1 = OrderItemModel(
            id: "1", productId: "a", name: "Espresso", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 60, costPrice: 20)
        let p2 = OrderItemModel(
            id: "2", productId: "b", name: "Latte", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 20, costPrice: 8)
        let p3 = OrderItemModel(
            id: "3", productId: "c", name: "Cake", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 15, costPrice: 5)
        let p4 = OrderItemModel(
            id: "4", productId: "d", name: "Water", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 5, costPrice: 1)

        let rows = service.buildABCRows(
            productsOfOrders: [p1, p2, p3, p4], range: range, rankingKey: .sales)

        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(rows[0].productId, "a")
        XCTAssertEqual(rows[0].sharePercent, 60, accuracy: 0.0001)
        XCTAssertEqual(rows[0].cumulativePercent, 60, accuracy: 0.0001)
        XCTAssertEqual(rows[0].bucket, .a)
        XCTAssertEqual(rows[1].productId, "b")
        XCTAssertEqual(rows[1].sharePercent, 20, accuracy: 0.0001)
        XCTAssertEqual(rows[1].cumulativePercent, 80, accuracy: 0.0001)
        XCTAssertEqual(rows[1].bucket, .b)
        XCTAssertEqual(rows[2].productId, "c")
        XCTAssertEqual(rows[2].sharePercent, 15, accuracy: 0.0001)
        XCTAssertEqual(rows[2].cumulativePercent, 95, accuracy: 0.0001)
        XCTAssertEqual(rows[2].bucket, .c)
        XCTAssertEqual(rows[3].productId, "d")
        XCTAssertEqual(rows[3].sharePercent, 5, accuracy: 0.0001)
        XCTAssertEqual(rows[3].cumulativePercent, 100, accuracy: 0.0001)
        XCTAssertEqual(rows[3].bucket, .c)
    }

    func testFinanceReporting_abcBuckets_byGrossProfit_reorders() {
        let service = FinanceReportingService()
        let aug15 = makeDate(year: 2026, month: 8, day: 15)
        let range = DashboardPeriod.month.interval(for: aug15)

        // Espresso: sales=50 cost=20 -> gross=30
        // Latte:    sales=40 cost=10 -> gross=30
        // Water:    sales=80 cost=70 -> gross=10
        let p1 = OrderItemModel(
            id: "1", productId: "a", name: "Espresso", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 50, costPrice: 20)
        let p2 = OrderItemModel(
            id: "2", productId: "b", name: "Latte", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 40, costPrice: 10)
        let p3 = OrderItemModel(
            id: "3", productId: "c", name: "Water", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 80, costPrice: 70)

        let rows = service.buildABCRows(
            productsOfOrders: [p1, p2, p3], range: range, rankingKey: .grossProfit)

        XCTAssertEqual(rows.count, 3)
        // по gross: Espresso/Latte (30) → then Water (10). Водночас share% = відсоток sales.
        XCTAssertEqual(rows[0].grossProfit, 30, accuracy: 0.0001)
        XCTAssertEqual(rows[1].grossProfit, 30, accuracy: 0.0001)
        XCTAssertEqual(rows[2].productId, "c")
        XCTAssertEqual(rows[2].grossProfit, 10, accuracy: 0.0001)
        let totalShare = rows.reduce(0) { $0 + $1.sharePercent }
        XCTAssertEqual(totalShare, 100, accuracy: 0.0001)
    }

    func testFinanceReporting_trendWindows_4days_countAndOrder() {
        let service = FinanceReportingService()
        let ref = makeDate(year: 2026, month: 8, day: 15)
        let windows = service.buildTrendWindows(
            periodicity: .day, periodsBack: 4, referenceDate: ref)

        XCTAssertEqual(windows.count, 4)
        // Windows [12, 13, 14, 15] - ascending chronological
        let cal = Calendar.current
        let firstComponents = cal.dateComponents([.day, .month, .year], from: windows.first!.start)
        let lastComponents = cal.dateComponents([.day, .month, .year], from: windows.last!.start)
        XCTAssertEqual(firstComponents.day, 12)
        XCTAssertEqual(lastComponents.day, 15)
        // Ascending order: end[i] <= start[i+1]
        for i in 0..<(windows.count - 1) {
            XCTAssertLessThanOrEqual(windows[i].end, windows[i + 1].start)
        }
    }

    func testFinanceReporting_trendWindows_3months_count() {
        let service = FinanceReportingService()
        let ref = makeDate(year: 2026, month: 8, day: 15)
        let windows = service.buildTrendWindows(
            periodicity: .month, periodsBack: 3, referenceDate: ref)

        XCTAssertEqual(windows.count, 3)
        // months 6/2026, 7/2026, 8/2026
        let cal = Calendar.current
        let months = windows.map { cal.dateComponents([.month], from: $0.start).month! }
        XCTAssertEqual(months, [6, 7, 8])
    }

    func testFinanceReporting_abcIgnoresItemsOutsideRange() {
        let service = FinanceReportingService()
        let aug15 = makeDate(year: 2026, month: 8, day: 15)
        let range = DashboardPeriod.day.interval(for: aug15)
        // 3 items: 1 in day, 2 in other days
        let inDay = OrderItemModel(
            id: "1", productId: "a", name: "A", orderId: "o1", date: aug15, quantity: 1,
            salePrice: 80, costPrice: 20)
        let outDay1 = OrderItemModel(
            id: "2", productId: "b", name: "B", orderId: "o2",
            date: aug15.addingTimeInterval(-86400), quantity: 1,
            salePrice: 100, costPrice: 50)
        let outDay2 = OrderItemModel(
            id: "3", productId: "c", name: "C", orderId: "o3",
            date: aug15.addingTimeInterval(+86400), quantity: 1,
            salePrice: 200, costPrice: 100)

        let rows = service.buildABCRows(
            productsOfOrders: [inDay, outDay1, outDay2], range: range, rankingKey: .sales)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].productId, "a")
        XCTAssertEqual(rows[0].sharePercent, 100, accuracy: 0.0001)
        XCTAssertEqual(rows[0].bucket, .a)
    }
}
