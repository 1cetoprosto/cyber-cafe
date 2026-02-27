//
//  SubscriptionType.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 29.06.2024.
//

import Foundation

enum SubscriptionType: String, CaseIterable {
    case none
    case proMonthly

    init?(rawValue: String) {
        guard let type = SubscriptionType.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
        self = type
    }

    var rawValue: String {
        switch self {
            case .none: return "none"
            case .proMonthly: return "icsoft.trackmycafe.pro.monthly"
        }
    }

    var productId: String? {
        switch self {
            case .none:
                return nil
            case .proMonthly:
                return rawValue
        }
    }

    var subscriptionId: String? {
        switch self {
            case .proMonthly: return "pro_monthly"
            default: return nil
        }
    }

    var name: String {
        switch self {
            case .none: return R.string.global.subPlanNoneName()
            case .proMonthly: return NSLocalizedString("subPlanProMonthlyName", tableName: "Global", comment: "")
        }
    }

    var info: String {
        switch self {
            case .none: return R.string.global.subPlanNoneDescription()
            case .proMonthly: return NSLocalizedString("subPlanProMonthlyDescription", tableName: "Global", comment: "")
        }
    }

    static var allProducts: [String] {
        return SubscriptionType.allCases.compactMap { $0.productId }
    }

    static var allProductsSet: Set<String> {
        return Set(allProducts)
    }
}

extension SubscriptionType {

    var staffCount: Int {
        switch self {
            case .none: return 0
            case .proMonthly: return 1000 // Unlimited/High limit
        }
    }
}

