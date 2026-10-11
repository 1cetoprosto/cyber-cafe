import Foundation

struct OrderSnapshotRepairResult {
    let order: OrderModel
    let products: [OrderItemModel]
    let didRepairProducts: Bool
    let didRepairOrder: Bool
}

struct OrderSnapshotRepairService {
    func repair(order: OrderModel, products: [OrderItemModel]) -> OrderSnapshotRepairResult {
        let repairedProducts = repairProducts(products, fallbackTotalCost: order.totalCost)
        let resolvedTotalCost = resolvedOrderTotalCost(
            currentTotalCost: order.totalCost,
            products: repairedProducts
        )

        let repairedOrder = OrderModel(
            id: order.id,
            date: order.date,
            type: order.type,
            sum: order.sum,
            cash: order.cash,
            card: order.card,
            totalCost: resolvedTotalCost,
            inventoryTracking: order.inventoryTracking,
            note: order.note
        )

        return OrderSnapshotRepairResult(
            order: repairedOrder,
            products: repairedProducts,
            didRepairProducts: repairedProducts != products,
            didRepairOrder: !resolvedTotalCost.isApproximatelyEqual(to: order.totalCost)
        )
    }

    func repairProducts(
        _ products: [OrderItemModel],
        fallbackTotalCost: Double
    ) -> [OrderItemModel] {
        guard !products.isEmpty else { return [] }

        var repaired = products.map(repairDirectSnapshotGaps)

        let missingIndices = repaired.indices.filter { index in
            let product = repaired[index]
            return product.quantity > 0
                && product.costPrice.isApproximatelyZero
                && product.totalCost.isApproximatelyZero
        }

        guard !missingIndices.isEmpty else { return repaired }

        let knownCost = repaired.reduce(0) { $0 + max($1.totalCost, 0) }
        let remainingCost = fallbackTotalCost - knownCost
        guard remainingCost > 0 else { return repaired }

        let weightedValues = missingIndices.map { index -> Double in
            let product = repaired[index]
            if !product.totalSale.isApproximatelyZero {
                return product.totalSale
            }
            return Double(max(product.quantity, 1))
        }
        let totalWeight = weightedValues.reduce(0, +)
        guard totalWeight > 0 else { return repaired }

        var allocatedCost = 0.0
        for (offset, index) in missingIndices.enumerated() {
            let weight = weightedValues[offset]
            let isLastItem = offset == missingIndices.count - 1
            let costSum =
                isLastItem
                ? max(remainingCost - allocatedCost, 0)
                : max(remainingCost * (weight / totalWeight), 0)

            allocatedCost += costSum
            repaired[index].costPrice =
                repaired[index].quantity > 0
                ? costSum / Double(repaired[index].quantity)
                : 0
        }

        return repaired
    }

    func resolvedOrderTotalCost(
        currentTotalCost: Double,
        products: [OrderItemModel]
    ) -> Double {
        let snapshotTotal = products.reduce(0) { $0 + max($1.totalCost, 0) }
        if snapshotTotal > 0 {
            return snapshotTotal
        }
        return currentTotalCost
    }

    private func repairDirectSnapshotGaps(_ product: OrderItemModel) -> OrderItemModel {
        // Direct gap repair is handled during FIR → Domain conversion
        // (`OrderItemModel.init(firebaseModel:)` backfills `costPrice` from the
        // stored `costSum`). `totalCost` is computed from `costPrice * quantity`,
        // so there is no separate stored total to backfill here.
        product
    }
}

extension Double {
    fileprivate var isApproximatelyZero: Bool {
        abs(self) < 0.000_1
    }

    fileprivate func isApproximatelyEqual(to other: Double) -> Bool {
        abs(self - other) < 0.000_1
    }
}
