//
//  AggregationTests.swift
//  TrackMyCafeTests
//
//  Finance aggregation formulas plus income / opex period filtering.
//

import XCTest

@testable import TrackMyCafe_Dev

final class AggregationTests: XCTestCase {
    // MARK: - Finance formulas

    func testFinanceAggregationService_summarize_producesGrossNetMargin() {
        let service = FinanceAggregationService()
        let income = IncomeSummary(
            sales: 1000, cash: 600, card: 400, cogs: 400, count: 0, last: [])
        let opex = OpexSummary(total: 200, count: 0, last: [])

        let result = service.summarize(income: income, opex: opex)

        XCTAssertEqual(result.sales, 1000)
        XCTAssertEqual(result.cogs, 400)
        XCTAssertEqual(result.grossProfit, 600, accuracy: 0.0001)
        XCTAssertEqual(result.opex, 200)
        XCTAssertEqual(result.netProfit, 400, accuracy: 0.0001)
        XCTAssertEqual(result.grossMarginPercent, 60, accuracy: 0.0001)
    }

    func testFinanceAggregationService_summarize_zeroSales_marginIsZero() {
        let service = FinanceAggregationService()
        let income = IncomeSummary(
            sales: 0, cash: 0, card: 0, cogs: 0, count: 0, last: [])
        let opex = OpexSummary(total: 50, count: 0, last: [])

        let result = service.summarize(income: income, opex: opex)

        XCTAssertEqual(result.netProfit, -50, accuracy: 0.0001)
        XCTAssertEqual(result.grossMarginPercent, 0, accuracy: 0.0001)
    }

    // MARK: - Income COGS aggregation + period filtering

    func testIncomeAggregationService_sumsCogsAndFiltersByDay() {
        let service = IncomeAggregationService()
        let ref = makeDate(year: 2026, month: 6, day: 22)
        let otherDay =
            Calendar.current.date(
                byAdding: .day, value: 1, to: ref) ?? ref
        let orders = [
            OrderModel(
                id: "o1", date: ref, type: "Hall",
                sum: 100, cash: 100, card: 0, totalCost: 30, note: nil),
            OrderModel(
                id: "o2", date: ref, type: "Hall",
                sum: 200, cash: 100, card: 100, totalCost: 80, note: nil),
            OrderModel(
                id: "o3", date: otherDay, type: "Hall",
                sum: 999, cash: 999, card: 0, totalCost: 500, note: nil),
        ]

        let summary = service.summarize(
            orders: orders, period: .day, referenceDate: ref)

        XCTAssertEqual(summary.sales, 300, accuracy: 0.0001)
        XCTAssertEqual(summary.cogs, 110, accuracy: 0.0001)
    }

    func testOpexAggregationService_filtersByPeriod() {
        let service = OpexAggregationService()
        let ref = makeDate(year: 2026, month: 6, day: 22)
        let otherMonth =
            Calendar.current.date(
                byAdding: .month, value: 1, to: ref) ?? ref
        let expenses = [
            OpexExpenseModel(
                id: "e1", date: ref, categoryId: "Rent",
                amount: 100, paymentAccount: .cash, note: nil),
            OpexExpenseModel(
                id: "e2", date: otherMonth, categoryId: "Rent",
                amount: 999, paymentAccount: .cash, note: nil),
        ]

        let summary = service.summarize(
            expenses: expenses, period: .month, referenceDate: ref)

        XCTAssertEqual(summary.total, 100, accuracy: 0.0001)
    }
}
