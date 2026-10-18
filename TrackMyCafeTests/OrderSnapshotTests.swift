//
//  OrderSnapshotTests.swift
//  TrackMyCafeTests
//
//  Order snapshot repair (cost price / total cost backfill).
//

import XCTest

@testable import TrackMyCafe_Dev

final class OrderSnapshotTests: XCTestCase {
    func testOrderSnapshotRepairService_totalCostComputedFromCostPrice() {
        let service = OrderSnapshotRepairService()
        let order = OrderModel(
            id: "order-1",
            date: makeDate(year: 2026, month: 6, day: 22),
            type: "Hall",
            sum: 90,
            cash: 90,
            card: 0,
            totalCost: 30
        )
        let products = [
            OrderItemModel(
                id: "item-1",
                productId: "product-1",
                name: "Latte",
                orderId: "order-1",
                date: order.date,
                quantity: 3,
                salePrice: 30,
                costPrice: 10
            )
        ]

        let result = service.repair(order: order, products: products)

        // `totalCost` is a computed property (`costPrice * quantity`), so when
        // `costPrice` is present no product-level repair is required.
        XCTAssertFalse(result.didRepairProducts)
        XCTAssertFalse(result.didRepairOrder)
        XCTAssertEqual(result.products.first?.totalCost, 30)
        XCTAssertEqual(result.order.totalCost, 30)
    }

    func testOrderSnapshotRepairService_allocatesMissingItemCostsFromOrderTotalCost() {
        let service = OrderSnapshotRepairService()
        let order = OrderModel(
            id: "order-2",
            date: makeDate(year: 2026, month: 6, day: 22),
            type: "Hall",
            sum: 100,
            cash: 100,
            card: 0,
            totalCost: 40
        )
        let products = [
            OrderItemModel(
                id: "item-1",
                productId: "product-1",
                name: "Espresso",
                orderId: "order-2",
                date: order.date,
                quantity: 1,
                salePrice: 40
            ),
            OrderItemModel(
                id: "item-2",
                productId: "product-2",
                name: "Latte",
                orderId: "order-2",
                date: order.date,
                quantity: 2,
                salePrice: 30
            ),
        ]

        let result = service.repair(order: order, products: products)

        XCTAssertTrue(result.didRepairProducts)
        XCTAssertFalse(result.didRepairOrder)
        XCTAssertEqual(result.products[0].totalCost, 16, accuracy: 0.0001)
        XCTAssertEqual(result.products[0].costPrice, 16, accuracy: 0.0001)
        XCTAssertEqual(result.products[1].totalCost, 24, accuracy: 0.0001)
        XCTAssertEqual(result.products[1].costPrice, 12, accuracy: 0.0001)
        XCTAssertEqual(result.order.totalCost, 40, accuracy: 0.0001)
    }

    func testOrderSnapshotRepairService_backfillsMissingOrderTotalCostFromItems() {
        let service = OrderSnapshotRepairService()
        let order = OrderModel(
            id: "order-3",
            date: makeDate(year: 2026, month: 6, day: 22),
            type: "Hall",
            sum: 100,
            cash: 50,
            card: 50,
            totalCost: 0
        )
        let products = [
            OrderItemModel(
                id: "item-1",
                productId: "product-1",
                name: "Flat White",
                orderId: "order-3",
                date: order.date,
                quantity: 2,
                salePrice: 25,
                costPrice: 7
            ),
            OrderItemModel(
                id: "item-2",
                productId: "product-2",
                name: "Tea",
                orderId: "order-3",
                date: order.date,
                quantity: 2,
                salePrice: 25,
                costPrice: 3
            ),
        ]

        let result = service.repair(order: order, products: products)

        XCTAssertFalse(result.didRepairProducts)
        XCTAssertTrue(result.didRepairOrder)
        XCTAssertEqual(result.order.totalCost, 20, accuracy: 0.0001)
    }
}
