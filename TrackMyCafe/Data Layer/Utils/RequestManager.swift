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

        mainRef = db.collection(FirebaseCollections.legacyUsers).document(masterRef)
        logger.notice("startListening: mainRef set to \(self.mainRef.path)")

        self.listenTo(FirebaseCollections.legacyTechnicians)
        self.listenTo(FirebaseCollections.legacyLogs)
        self.listenToSettings()
        self.listenToSubscription()
        self.listenTo(FirebaseCollections.legacyOrders)
        self.listenToAdmin {
            // Обробка після завантаження даних адміністратора
            NotificationCenter.default.post(name: .adminInfoReload, object: nil)
        }

        IAPManager.shared.verifySubscription { receipt in
            if let receipt = receipt, receipt.hasActiveAutorenewSubscription {
                IAPManager.shared.isProPlan = true
                NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
            }

            Task {
                _ = await IAPManager.shared.refreshProStatusUsingStoreKit2()
            }
        }
    }

    // MARK: - Doctors

    func listenTo(_ collection: String) {
        if Auth.auth().currentUser != nil {

            var items: [AnyObject] = []
            var notifName = NSNotification.Name("")

            switch collection {
            case FirebaseCollections.legacyOrders:
                notifName = .ordersInfoReload
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
                case FirebaseCollections.legacyOrders:
                    self.orders = items as! [OrderModel]
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
        } else if collection == FirebaseCollections.legacyOrders {
            return OrderModel(object) as AnyObject
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

    // MARK: - Settings

    func listenToSettings() {
        if Auth.auth().currentUser != nil {
            mainRef.collection(FirebaseCollections.legacySettings).addSnapshotListener {
                (snapshot, error) in
                guard let snapshot = snapshot else {
                    self.logger.log(
                        "Error listening to Settings collection: \(error?.localizedDescription ?? "No error description")"
                    )
                    return
                }

                if !snapshot.documents.isEmpty {
                    self.settings = Settings(
                        snapshot.documents.first!.data() as [String: AnyObject])
                    NotificationCenter.default.post(name: .settingsInfoReload, object: nil)
                } else {
                    self.settings = Settings()
                }
            }
        }
    }

    func listenToAdmin(completion: @escaping () -> Void) {
        guard let mainRef = mainRef else {
            logger.log("mainRef is nil")
            completion()
            return
        }
        debugPrint(mainRef)
        let fields = [
            FirebaseFields.email, FirebaseFields.firstName, FirebaseFields.lastName,
            FirebaseFields.middleName, FirebaseFields.phone, FirebaseFields.address,
            FirebaseFields.avatarThumbnailUrl, FirebaseFields.avatarUrl, FirebaseFields.comment,
        ]
        var pendingFields = Set(fields)
        for field in fields {
            mainRef.collection(field).addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    logger.log(
                        "Error listening to Admin \(field): \(error?.localizedDescription ?? "No error description")"
                    )
                    return
                }

                guard let value = snapshot.documents.first?.data()["value"] as? String else {
                    return
                }

                switch field {
                case FirebaseFields.email:
                    self.admin.email = value
                case FirebaseFields.firstName:
                    self.admin.firstName = value
                case FirebaseFields.lastName:
                    self.admin.lastName = value
                case FirebaseFields.middleName:
                    self.admin.middleName = value
                case FirebaseFields.phone:
                    self.admin.phone = value
                case FirebaseFields.address:
                    self.admin.address = value
                case FirebaseFields.avatarThumbnailUrl:
                    self.admin.avatarThumbnailUrl = value
                case FirebaseFields.avatarUrl:
                    self.admin.avatarUrl = value
                case FirebaseFields.comment:
                    self.admin.comment = value
                default:
                    break
                }

                pendingFields.remove(field)
                if pendingFields.isEmpty {
                    completion()
                }
            }
        }
    }

    // MARK: - Subscription

    func listenToSubscription() {
        if Auth.auth().currentUser != nil {
            mainRef.collection(FirebaseCollections.legacySubscription).addSnapshotListener {
                (snapshot, error) in
                guard let snapshot = snapshot else {
                    self.logger.log(
                        "Error listening to Subscriptions collection: \(error?.localizedDescription ?? "No error description")"
                    )
                    return
                }

                if let document = snapshot.documents.first {
                    self.subscription = Subscription(document.data() as [String: AnyObject])
                } else {
                    self.subscription = Subscription()
                }
                IAPManager.shared.updateInfo(self.subscription!)

                // Checking for subscription expiration
                if let subscription = self.subscription,
                    let nextPaymentDate = subscription.nextPaymentDate,
                    nextPaymentDate < Date.subCheckDate()
                {
                    let controller = SubscriptionController.makeExpired()
                    UIViewController.topMostViewController()?.present(controller, animated: true)
                }

                NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
            }
        }
    }

    func getSubscriptionInfo(_ completion: @escaping (Subscription) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(Subscription())
            return
        }

        guard let mainRef = mainRef else {
            completion(Subscription())
            return
        }

        mainRef.collection(FirebaseCollections.legacySubscription).getDocuments { (snapshot, _) in
            guard let snapshot = snapshot, let document = snapshot.documents.first else {
                completion(Subscription())
                return
            }
            completion(Subscription(document.data() as [String: AnyObject]))
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

        if let ref = mainRef {
            ref.collection(FirebaseCollections.legacySubscription).document(
                UserSession.current.dataRef
            )
            .setData(data)
            Firestore.firestore().collection(FirebaseCollections.subscriptions).document(
                UserSession.current.dataRef
            ).setData(data)
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
