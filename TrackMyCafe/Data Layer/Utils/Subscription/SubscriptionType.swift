//
//  SubscriptionType.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 29.06.2024.
//

import Foundation

enum SubscriptionType: String, CaseIterable {
    case none
    case single
    case mini
    case penta
    case mid
    case big
    case maxi
    case premium
    
    init?(rawValue: String) {
        guard let type = SubscriptionType.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
        self = type
    }
    
    var rawValue: String {
        let bundleId = Bundle.main.bundleIdentifier!
        switch self {
            case .none: return "none"
            case .single: return "\(bundleId).sub.single"
            case .mini: return "\(bundleId).sub.mini"
            case .penta: return "\(bundleId).sub.penta"
            case .mid: return "\(bundleId).sub.mid"
            case .big: return "\(bundleId).sub.big"
            case .maxi: return "\(bundleId).sub.maxi"
            case .premium: return "premium"
        }
    }
    
    var productId: String? {
        switch self {
            case .none, .premium:
                return nil
            default:
                return rawValue
        }
    }
    
    var subscriptionId: String? {
        switch self {
            case .single: return "single"
            case .mini: return "mini_lab"
            case .penta: return "penta_lab"
            case .mid: return "mid_lab"
            case .big: return "big_lab"
            case .maxi: return "maxi_lab"
            default: return nil
        }
    }
    
    var name: String {
        switch self {
            case .none: return R.string.global.subPlanNoneName()
            case .single: return R.string.global.subPlanSingleName()
            case .mini: return R.string.global.subPlanMiniName()
            case .penta: return R.string.global.subPlanPentaName()
            case .mid: return R.string.global.subPlanMidName()
            case .big: return R.string.global.subPlanBigName()
            case .maxi: return R.string.global.subPlanMaxiName()
            case .premium: return R.string.global.subPlanPremiumName()
        }
    }
    
    var info: String {
        switch self {
            case .none: return R.string.global.subPlanNoneDescription()
            case .single: return R.string.global.subPlanSingleDescription()
            case .mini: return R.string.global.subPlanMiniDescription()
            case .penta: return R.string.global.subPlanPentaDescription()
            case .mid: return R.string.global.subPlanMidDescription()
            case .big: return R.string.global.subPlanBigDescription()
            case .maxi: return R.string.global.subPlanMaxiDescription()
            case .premium: return R.string.global.subPlanPremiumDescription()
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
            case .single: return 1
            case .mini: return 2
            case .penta: return 5
            case .mid: return 12
            case .big: return 20
            case .maxi: return 30
            case .premium: return 1000
        }
    }
}

