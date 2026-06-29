import Foundation

struct OrderSnapshotRepairResult {
    let order: OrderModel
    let products: [ProductOfOrderModel]
    let didRepairProducts: Bool
    let didRepairOrder: Bool
}

struct OrderSnapshotRepairService {
    func repair(order: OrderModel, products: [ProductOfOrderModel]) -> OrderSnapshotRepairResult {
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
        _ products: [ProductOfOrderModel],
        fallbackTotalCost: Double
    ) -> [ProductOfOrderModel] {
        guard !products.isEmpty else { return [] }

        var repaired = products.map(repairDirectSnapshotGaps)

        let missingIndices = repaired.indices.filter { index in
            let product = repaired[index]
            return product.quantity > 0
                && product.costPrice.isApproximatelyZero
                && product.costSum.isApproximatelyZero
        }

        guard !missingIndices.isEmpty else { return repaired }

        let knownCost = repaired.reduce(0) { $0 + max($1.costSum, 0) }
        let remainingCost = fallbackTotalCost - knownCost
        guard remainingCost > 0 else { return repaired }

        let weightedValues = missingIndices.map { index -> Double in
            let product = repaired[index]
            if !product.sum.isApproximatelyZero {
                return product.sum
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
            repaired[index].costSum = costSum
            repaired[index].costPrice =
                repaired[index].quantity > 0
                ? costSum / Double(repaired[index].quantity)
                : 0
        }

        return repaired
    }

    func resolvedOrderTotalCost(
        currentTotalCost: Double,
        products: [ProductOfOrderModel]
    ) -> Double {
        let snapshotTotal = products.reduce(0) { $0 + max($1.costSum, 0) }
        if snapshotTotal > 0 {
            return snapshotTotal
        }
        return currentTotalCost
    }

    private func repairDirectSnapshotGaps(_ product: ProductOfOrderModel) -> ProductOfOrderModel {
        var repaired = product

        if repaired.quantity > 0 && repaired.costSum.isApproximatelyZero && repaired.costPrice > 0 {
            repaired.costSum = repaired.costPrice * Double(repaired.quantity)
        }

        if repaired.quantity > 0 && repaired.costPrice.isApproximatelyZero && repaired.costSum > 0 {
            repaired.costPrice = repaired.costSum / Double(repaired.quantity)
        }

        return repaired
    }
}

private extension Double {
    var isApproximatelyZero: Bool {
        abs(self) < 0.000_1
    }

    func isApproximatelyEqual(to other: Double) -> Bool {
        abs(self - other) < 0.000_1
    }
}
