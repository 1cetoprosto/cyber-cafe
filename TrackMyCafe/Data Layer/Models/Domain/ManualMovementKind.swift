import Foundation

enum ManualMovementKind: String, Codable, CaseIterable {
    case deposit
    case withdrawal
    case transfer
    case adjustment
}

