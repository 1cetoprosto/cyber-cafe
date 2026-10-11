import Foundation

// MARK: - OrderItemModel
//
// Canonical domain model for a single line of an order (product in a check).
// See `docs/internal/ARCHITECTURE_AND_LOGIC.md` → section 1.3 (Sale / Order).
//
// Target shape (spec): id, productId, quantity, salePrice, costPrice.
//
// Intentional v1.x extensions from the target spec:
// - `name` is denormalized onto the line so the order-details product list can
//   render without an extra product-catalog lookup (display convenience).
// - `orderId` links the line back to its parent order (persistence grouping).
// - `date` is denormalized for date-range queries without joining the order.
// - `costPrice` is mutable so the snapshot-repair service can backfill missing
//   COGS for legacy orders that were saved without cost snapshots.
//
// This model replaced the legacy `ProductOfOrderModel` (v1.1.3). `totalSale`
// and `totalCost` are computed from the line values; Firestore keeps the
// round-tripped `amount` / `costSum` fields for backward compatibility.

struct OrderItemModel: Identifiable, Codable, Equatable {
    var id: String
    let productId: String
    var name: String
    var orderId: String
    var date: Date
    var quantity: Int
    var salePrice: Double  // Price at the moment of sale
    var costPrice: Double  // COGS at the moment of sale (mutable for snapshot repair)

    var totalSale: Double { salePrice * Double(quantity) }
    var totalCost: Double { costPrice * Double(quantity) }

    init(
        id: String = UUID().uuidString,
        productId: String,
        name: String = "",
        orderId: String = "",
        date: Date = Date(),
        quantity: Int,
        salePrice: Double,
        costPrice: Double = 0.0  // Can be calculated later or passed during creation
    ) {
        self.id = id
        self.productId = productId
        self.name = name
        self.orderId = orderId
        self.date = date
        self.quantity = quantity
        self.salePrice = salePrice
        self.costPrice = costPrice
    }

    init(firebaseModel: FIRProductModel) {
        self.id = firebaseModel.id ?? UUID().uuidString
        self.productId = firebaseModel.productId ?? ""
        self.name = firebaseModel.name
        self.orderId = firebaseModel.orderId ?? ""
        self.date = firebaseModel.date
        self.quantity = firebaseModel.quantity
        self.salePrice = firebaseModel.price
        // Backfill costPrice from the stored costSum for legacy documents that
        // were saved without a per-unit cost snapshot. `totalCost` is computed
        // from costPrice, so we must restore costPrice here; otherwise the
        // repair service cannot recover the value from costSum alone.
        if abs(firebaseModel.costPrice) < 0.000_1,
            firebaseModel.costSum > 0,
            firebaseModel.quantity > 0
        {
            self.costPrice = firebaseModel.costSum / Double(firebaseModel.quantity)
        } else {
            self.costPrice = firebaseModel.costPrice
        }
    }
}
