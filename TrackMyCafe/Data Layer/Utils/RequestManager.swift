//
//  RequestManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit
import os.log

enum SubscriptionPurchaseLinkStatus {
    case notLinked
    case linkedCurrent
    case linkedAnother
}

class RequestManager: NSObject {

    static let shared = RequestManager()
    var db: Firestore!
    var mainRef: DocumentReference!

    // TODO: - Add observer
    private var _userAvatarPath: String?
    var userAvatarPath: String? {
        if UserSession.current.isAdmin { return admin.avatarThumbnailUrl }
        return RequestManager.shared.employees.first {
            $0.firebaseRef == UserSession.current.employeeRef
        }?.avatarThumbnailUrl
    }

    private var _orders = [OrderModel]()
    var orders: [OrderModel] {
        get {
            return _orders
        }
        set {
            _orders = newValue
        }
    }

    var admin = Admin() {
        didSet {
            NotificationCenter.default.post(name: .adminInfoReload, object: nil)
        }
    }
    var employees = [Employee]()
    var logs = [Log]()
    var users = [User]()
    var roles = [RoleConfig]()
    var settings: Settings?
    var subscription: Subscription?

    /// Prevents `startListening()` from registering duplicate snapshot listeners
    /// when called from both the fresh-login path (`AuthManager`) and the
    /// session-restore path (`SceneDelegate`).
    private var hasStartedListening = false

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "RequestManager")

    override init() {
        super.init()
        db = Firestore.firestore()
        admin.firebaseRef = UserSession.current.masterUserRef
    }

    // MARK: - Listeners

    func resetData() {
        orders = []
        employees = []
        logs = []
        users = []
        roles = []
        settings = nil
        hasStartedListening = false
    }

    func startListening() {
        guard !hasStartedListening else {
            logger.warning("startListening: already started, skipping")
            return
        }
        guard Auth.auth().currentUser != nil else {
            logger.error("startListening: no authenticated user, aborting")
            return
        }
        guard let masterRef = UserSession.current.masterUserRef else {
            logger.error("startListening: masterUserRef is nil, aborting")
            return
        }
        hasStartedListening = true
        logger.notice("startListening: called, masterUserRef=\(masterRef)")

        // Cafe root is lowercase `users/{uid}` (profile + staff + Settings map).
        mainRef = db.collection(FirebaseCollections.users).document(masterRef)
        logger.notice("startListening: mainRef set to \(self.mainRef.path)")

        self.listenTo(FirebaseCollections.legacyTechnicians)
        self.listenTo(FirebaseCollections.legacyLogs)
        self.listenToUserProfileDocument()
        self.flushPendingSubscriptionSyncIfNeeded()
        self.listenToSubscription()
        // Orders CRUD uses lowercase `orders` via DomainDatabaseService; the
        // legacy PascalCase `Orders` listener is removed (unused dual path).

        IAPManager.shared.verifySubscription { receipt in
            if let receipt = receipt, receipt.hasActiveAutorenewSubscription {
                IAPManager.shared.isProPlan = true
                NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
            }

            Task {
                // Prefer cafe-level Firebase Pro so staff devices keep access
                // even without a local App Store purchase.
                _ = await IAPManager.shared.resolveProAccess()
            }
        }
    }

    // MARK: - Doctors

    func listenTo(_ collection: String) {
        if Auth.auth().currentUser != nil {

            var items: [AnyObject] = []
            var notifName = NSNotification.Name("")

            switch collection {
            case FirebaseCollections.legacyTechnicians:
                notifName = .employeesInfoReload
            case FirebaseCollections.legacyLogs:
                notifName = .logsInfoReload
            default:
                logger.log("should not be here")
            }

            mainRef.collection(collection).addSnapshotListener { (snapshot, error) in
                guard let snapshot = snapshot else {
                    self.logger.log(
                        "Error listening to collection \(collection): \(error?.localizedDescription ?? "No error description")"
                    )
                    return
                }

                if collection == FirebaseCollections.legacyTechnicians {
                    self.logger.notice(
                        "Technicians snapshot: \(snapshot.documents.count) document(s)"
                    )
                }

                items.removeAll()

                for document in snapshot.documents {
                    guard
                        let item = self.map(
                            document.data() as [String: AnyObject], collection)
                    else {
                        if collection == FirebaseCollections.legacyTechnicians {
                            let data = document.data()
                            self.logger.error(
                                "Failed to parse employee doc \(document.documentID): keys=\(Array(data.keys)), createdDate=\(String(describing: data[FirebaseFields.createdDate])), type=\(String(describing: type(of: data[FirebaseFields.createdDate])))"
                            )
                        }
                        continue
                    }
                    items.append(item)
                }

                if collection == FirebaseCollections.legacyTechnicians {
                    self.logger.notice(
                        "Technicians parsed: \(items.count) employee(s)"
                    )
                }

                switch collection {
                case FirebaseCollections.legacyTechnicians:
                    self.employees = items as! [Employee]
                case FirebaseCollections.legacyLogs:
                    self.logs = items as! [Log]
                default:
                    self.logger.log("Unhandled collection: \(collection)")
                }

                NotificationCenter.default.post(name: notifName, object: nil)
            }
        }
    }

    func map(_ object: [String: AnyObject], _ collection: String) -> AnyObject? {
        if collection == FirebaseCollections.legacyTechnicians {
            return Employee(object)
        } else if collection == FirebaseCollections.legacyLogs {
            let element = Log(
                date: Date(timeIntervalSince1970: object[FirebaseFields.timestamp] as! Double),
                object: object["object"] as! String,
                action: ActionType(rawValue: object["action"] as! String)!,
                description: object["description"] as! String)
            element.firebaseRef = object[FirebaseFields.firebaseRef] as? String
            element.objectRef = object["objectRef"] as? String
            return element
        }

        return nil
    }

    // MARK: - Profile (admin + Settings map on `users/{uid}`)

    /// Listens to the cafe root document for admin profile fields and the nested
    /// `Settings` map. Replaces the old `Users/{uid}/{field}` subcollection layout.
    func listenToUserProfileDocument() {
        guard Auth.auth().currentUser != nil, let mainRef = mainRef else { return }

        mainRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error {
                self.logger.error(
                    "Error listening to user profile: \(error.localizedDescription)")
                return
            }
            guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                self.settings = Settings()
                NotificationCenter.default.post(name: .settingsInfoReload, object: nil)
                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
                return
            }

            self.applyAdminFields(from: data)
            if let settingsMap = data[FirebaseCollections.legacySettings] as? [String: Any] {
                self.settings = Settings(settingsMap as [String: AnyObject])
            } else {
                self.settings = Settings()
            }

            NotificationCenter.default.post(name: .settingsInfoReload, object: nil)
            NotificationCenter.default.post(name: .adminInfoReload, object: nil)
        }
    }

    /// Public entry used by Admin UI; profile is already live via
    /// `listenToUserProfileDocument()`, so this just re-posts current state.
    func listenToAdmin(completion: @escaping () -> Void) {
        guard mainRef != nil else {
            logger.log("mainRef is nil")
            completion()
            return
        }
        NotificationCenter.default.post(name: .adminInfoReload, object: nil)
        completion()
    }

    private func applyAdminFields(from data: [String: Any]) {
        admin.firebaseRef = mainRef?.documentID ?? admin.firebaseRef
        admin.email = data[FirebaseFields.email] as? String ?? admin.email
        admin.firstName = data[FirebaseFields.firstName] as? String ?? admin.firstName
        admin.lastName = data[FirebaseFields.lastName] as? String
        admin.middleName = data[FirebaseFields.middleName] as? String
        admin.phone = data[FirebaseFields.phone] as? String
        admin.address = data[FirebaseFields.address] as? String
        admin.avatarThumbnailUrl = data[FirebaseFields.avatarThumbnailUrl] as? String
        admin.avatarUrl = data[FirebaseFields.avatarUrl] as? String
        admin.comment = data[FirebaseFields.comment] as? String
    }

    // MARK: - Subscription

    /// Canonical path: `Subscriptions/{uid}`.
    func listenToSubscription() {
        guard Auth.auth().currentUser != nil else { return }
        guard let docId = UserSession.current.dataRef, !docId.isEmpty else {
            logger.error("listenToSubscription: dataRef is nil")
            return
        }

        db.collection(FirebaseCollections.subscriptions).document(docId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error {
                    self.logger.error(
                        "Error listening to Subscriptions/\(docId): \(error.localizedDescription)")
                    return
                }

                if let snapshot, snapshot.exists, let data = snapshot.data() {
                    self.applySubscription(data)
                } else {
                    self.applySubscription([:])
                }
            }
    }

    private func applySubscription(_ data: [String: Any]) {
        subscription = data.isEmpty ? Subscription() : Subscription(data)
        if let subscription {
            IAPManager.shared.updateInfo(subscription)
        }
        NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
        presentExpiredPaywallIfNeeded()
    }

    /// Trial bought before login is stored locally; push it once session exists.
    private func flushPendingSubscriptionSyncIfNeeded() {
        guard
            let data = UserDefaults.standard.dictionary(
                forKey: UserDefaultsKeys.pendingSubscriptionSync)
        else { return }
        guard let docId = UserSession.current.dataRef else { return }

        if UserSession.current.isAuth, !UserSession.current.canManageSubscription {
            return
        }

        db.collection(FirebaseCollections.subscriptions).document(docId).setData(data)

        if let ts = data["nextPaymentDate"] as? Double {
            IAPManager.shared.nextPaymentDate = Date(timeIntervalSince1970: ts)
        }
        IAPManager.shared.isProPlan = true
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.pendingSubscriptionSync)
        NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
        logger.notice("Flushed pending subscription sync to Subscriptions/\(docId)")
    }

    /// Shows the expired paywall only when cafe access is truly gone — not when
    /// StoreKit still has an active trial and Firebase is stale/empty.
    private func presentExpiredPaywallIfNeeded() {
        guard let subscription = subscription,
            let nextPaymentDate = subscription.nextPaymentDate,
            nextPaymentDate < Date.subCheckDate()
        else { return }

        Task { @MainActor in
            let isPro = await IAPManager.shared.resolveProAccess()
            guard !isPro else { return }

            guard let top = UIViewController.topMostViewController() else { return }
            if top is SubscriptionController { return }
            if top.presentedViewController is SubscriptionController { return }

            let controller = SubscriptionController.makeExpired()
            top.present(controller, animated: true)
        }
    }

    func getSubscriptionInfo(_ completion: @escaping (Subscription) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(Subscription())
            return
        }
        guard let docId = UserSession.current.dataRef, !docId.isEmpty else {
            completion(Subscription())
            return
        }

        db.collection(FirebaseCollections.subscriptions).document(docId).getDocument {
            snapshot, _
            in
            if let snapshot, snapshot.exists, let data = snapshot.data() {
                completion(Subscription(data))
            } else {
                completion(Subscription())
            }
        }
    }

    func isSubscriptionPurchaseLinkedToAccount(
        _ originTransactionId: String,
        completion: @escaping (SubscriptionPurchaseLinkStatus?) -> Void
    ) {
        let connectedRef = Firestore.firestore().collection(FirebaseCollections.info).document(
            FirebaseFields.connected)
        connectedRef.addSnapshotListener { snapshot, _ in
            if let snapshot = snapshot, snapshot.exists,
                snapshot.data()?[FirebaseFields.connected] as? Bool ?? false
            {
                let subscriptionsRef = Firestore.firestore().collection(
                    FirebaseCollections.subscriptions)
                subscriptionsRef.whereField(
                    "iosOriginTransactionId", isEqualTo: originTransactionId
                )
                .getDocuments { (snapshot, _) in
                    if let snapshot = snapshot, let data = snapshot.documents.first {
                        let labKey = data.documentID
                        completion(
                            labKey == UserSession.current.dataRef ? .linkedCurrent : .linkedAnother)
                    } else {
                        completion(.notLinked)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }

    func updateSubInfo(
        _ productId: String, transactionId: String, originTransactionId: String, paymentDate: Date,
        nextPaymentDate: Date
    ) {
        // Staff must never mutate the cafe subscription document.
        // Allow writes only for the owner, or for a pre-login pending sync.
        if UserSession.current.isAuth, !UserSession.current.canManageSubscription {
            logger.notice(
                "Skipping subscription write for non-admin role: \(String(describing: UserSession.current.role))"
            )
            return
        }

        var data: [String: Any] = [
            "providerId": "ios",
            "iosProductId": productId,
            "iosTransactionId": transactionId,
            "iosOriginTransactionId": originTransactionId.isEmpty
                ? transactionId : originTransactionId,
            "paymentDate": paymentDate.timeIntervalSince1970,
            "nextPaymentDate": nextPaymentDate.timeIntervalSince1970,
            "premiumPlan": true,
        ]
        if let subscriptionId = SubscriptionType(rawValue: productId)?.subscriptionId {
            data["subscriptionId"] = subscriptionId
        }

        if let docId = UserSession.current.dataRef, !docId.isEmpty {
            db.collection(FirebaseCollections.subscriptions).document(docId).setData(data)
            // Also update IAPManager state directly so UI reflects changes immediately
            IAPManager.shared.isProPlan = true
            IAPManager.shared.nextPaymentDate = nextPaymentDate
            NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
        } else {
            // User not logged in, save locally to UserDefaults for later sync
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.pendingSubscriptionSync)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.subscriptionIsProPlan)
            // Also update IAPManager state directly so UI reflects changes immediately
            IAPManager.shared.isProPlan = true
            IAPManager.shared.nextPaymentDate = nextPaymentDate

            NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
        }
    }

    // MARK: - Logs
    func log(
        date: Date, object: String, action: ActionType, description: String, objectRef: String? = ""
    ) {
        if Auth.auth().currentUser != nil {
            let db = Firestore.firestore()
            let logsRef = db.collection(FirebaseCollections.legacyLogs).document()

            let data: [String: Any] = [
                FirebaseFields.timestamp: date.interval as Int,
                "object": object as String,
                "action": action.rawValue as String,
                "description": description as String,
                FirebaseFields.firebaseRef: logsRef.documentID,
                "objectRef": objectRef ?? "",
            ]

            logsRef.setData(data) { error in
                if let error = error {
                    self.logger.log("LOG: FIRESTORE ERROR - \(error.localizedDescription)!")
                } else {
                    self.logger.log("Data logged successfully!")
                }
            }
        }
    }
}
