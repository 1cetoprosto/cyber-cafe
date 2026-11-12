//
//  SubscriptionAccessTests.swift
//  TrackMyCafeTests
//
//  Cafe-level Pro access rules: staff share the owner's subscription.
//

import XCTest

@testable import TrackMyCafe_Dev

final class SubscriptionAccessTests: XCTestCase {

    func testGrantsProAccessWhenPremiumPlanFlagIsTrue() {
        let subscription = Subscription()
        subscription.proPlan = true

        XCTAssertTrue(subscription.grantsProAccess)
    }

    func testGrantsProAccessWhenActiveIOSSubscriptionExists() {
        let subscription = Subscription([
            "providerId": "ios",
            "premiumPlan": false,
            "iosProductId": "pro.monthly",
            "iosTransactionId": "tx_1",
            "iosOriginTransactionId": "orig_1",
            "paymentDate": Date().timeIntervalSince1970,
            "nextPaymentDate": Date().addingTimeInterval(86_400).timeIntervalSince1970,
        ])

        XCTAssertTrue(subscription.hasIOSSub)
        XCTAssertTrue(subscription.isActive)
        XCTAssertTrue(subscription.grantsProAccess)
    }

    func testDoesNotGrantProAccessWhenSubscriptionExpired() {
        let subscription = Subscription([
            "providerId": "ios",
            "premiumPlan": false,
            "iosProductId": "pro.monthly",
            "iosTransactionId": "tx_1",
            "iosOriginTransactionId": "orig_1",
            "paymentDate": Date().addingTimeInterval(-172_800).timeIntervalSince1970,
            "nextPaymentDate": Date().addingTimeInterval(-86_400).timeIntervalSince1970,
        ])

        XCTAssertTrue(subscription.hasIOSSub)
        XCTAssertFalse(subscription.isActive)
        XCTAssertFalse(subscription.grantsProAccess)
    }

    func testDoesNotGrantProAccessForEmptySubscription() {
        let subscription = Subscription()
        XCTAssertFalse(subscription.grantsProAccess)
    }

    func testOnlyAdministratorCanManageSubscription() {
        XCTAssertTrue(SubscriptionAccessPolicy.canManageSubscription(role: .administrator))
        XCTAssertFalse(SubscriptionAccessPolicy.canManageSubscription(role: .moderator))
        XCTAssertFalse(SubscriptionAccessPolicy.canManageSubscription(role: .waiter))
        XCTAssertFalse(SubscriptionAccessPolicy.canManageSubscription(role: .techMod))
        XCTAssertFalse(SubscriptionAccessPolicy.canManageSubscription(role: nil))
    }
}
