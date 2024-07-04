//
//  RequestManager.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
        return RequestManager.shared.technicians.first { $0.firebaseRef == UserSession.current.techRef }?.avatarThumbnailUrl
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
    
    var admin = Admin()
    var technicians = [Technician]()
    var logs = [Log]()
    var users = [User]()
    var roles = [RoleConfig]()
    var settings: Settings?
    var subscription: Subscription?
    
    override init() {
        super.init()
        db = Firestore.firestore()
        admin.firebaseRef = UserSession.current.masterUserRef
    }
    
    // MARK: - Listeners
    
    func resetData() {
        orders = []
        technicians = []
        logs = []
        users = []
        roles = []
        settings = nil
    }
    
    func startListening() {
        if Auth.auth().currentUser != nil {
            if let masterRef = UserSession.current.masterUserRef {
                mainRef = db.collection(Refs.users.rawValue).document(masterRef)
            }
            self.listenTo(.technicians)
            self.listenTo(.logs)
            self.listenToSettings()
            self.listenToSubscription()
            self.listenTo(.orders)
            self.listenToAdmin()
        } else {
            //db.removeAllObservers()
        }
    }
    
    // MARK: - Doctors
    
    func listenTo(_ refId: Refs) {
        if Auth.auth().currentUser != nil {
            
            var items: [AnyObject] = []
            var notifName = NSNotification.Name("")
            
            switch refId {
            case .orders:
                notifName = .ordersInfoReload
            case .technicians:
                notifName = .techniciansInfoReload
            case .logs:
                notifName = .logsInfoReload
            default:
                print("should not be here")
            }
            
            mainRef.collection(refId.rawValue).addSnapshotListener { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error listening to collection \(refId.rawValue): \(error?.localizedDescription ?? "No error description")")
                    return
                }
                
                items.removeAll()
                
                for document in snapshot.documents {
                    guard let item = self.map(document.data() as [String : AnyObject], refId) else { continue }
                    items.append(item)
                }
                
                switch refId {
                case .orders:
                    self.orders = items as! [OrderModel]
                case .technicians:
                    self.technicians = items as! [Technician]
                case .logs:
                    self.logs = items as! [Log]
                default:
                    print(items)
                }
                
                NotificationCenter.default.post(name: notifName, object: nil)
            }
        }
    }
    
    func map(_ object: [String : AnyObject], _ refId: Refs) -> AnyObject? {
        if refId == .technicians {
            return Technician(object)
        } else if refId == .orders {
            return OrderModel(object) as AnyObject
        } else if refId == .logs {
            let element = Log(date: Date(timeIntervalSince1970: object["timestamp"] as! Double),
                              object: Refs(rawValue: object["object"] as! String)!,
                              action: ActionType(rawValue: object["action"] as! String)!,
                              description: object["description"] as! String)
            element.firebaseRef = object["firebaseRef"] as? String
            element.objectRef = object["objectRef"] as? String
            return element
        }
        
        return nil
    }
    
    // MARK: - Settings
    
    func listenToSettings() {
        if Auth.auth().currentUser != nil {
            mainRef.collection(Refs.settings.rawValue).addSnapshotListener { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error listening to Settings collection: \(error?.localizedDescription ?? "No error description")")
                    return
                }
                
                if !snapshot.documents.isEmpty {
                    self.settings = Settings(snapshot.documents.first!.data() as [String : AnyObject])
                    NotificationCenter.default.post(name: .settingsInfoReload, object: nil)
                } else {
                    self.settings = Settings()
                }
            }
        }
    }
    
    func listenToAdmin() {
        let fields = ["email", "firstName", "lastName", "middleName", "phone", "address", "avatarThumbnailUrl", "avatarUrl", "comment"]
        for field in fields {
            mainRef.collection(field).addSnapshotListener { [weak self] (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error listening to Admin \(field): \(error?.localizedDescription ?? "No error description")")
                    return
                }
                
                guard let value = snapshot.documents.first?.data()["value"] as? String else { return }
                
                switch field {
                case "email":
                    self?.admin.email = value
                case "firstName":
                    self?.admin.firstName = value
                case "lastName":
                    self?.admin.lastName = value
                case "middleName":
                    self?.admin.middleName = value
                case "phone":
                    self?.admin.phone = value
                case "address":
                    self?.admin.address = value
                case "avatarThumbnailUrl":
                    self?.admin.avatarThumbnailUrl = value
                case "avatarUrl":
                    self?.admin.avatarUrl = value
                case "comment":
                    self?.admin.comment = value
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Subscription
    
    func listenToSubscription() {
        if Auth.auth().currentUser != nil {
            mainRef.collection(Refs.subscription.rawValue).addSnapshotListener { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error listening to Subscriptions collection: \(error?.localizedDescription ?? "No error description")")
                    return
                }
                
                if let document = snapshot.documents.first {
                    self.subscription = Subscription(document.data() as [String: AnyObject])
                } else {
                    self.subscription = Subscription()
                }
                IAPManager.shared.updateInfo(self.subscription!)
                NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
            }
        }
    }

    func getSubscriptionInfo(_ completion: @escaping (Subscription) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(Subscription())
            return
        }
        mainRef.collection(Refs.subscription.rawValue).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot, let document = snapshot.documents.first else {
                completion(Subscription())
                return
            }
            completion(Subscription(document.data() as [String: AnyObject]))
        }
    }

    func isSubscriptionPurchaseLinkedToAccount(_ originTransactionId: String, completion: @escaping (SubscriptionPurchaseLinkStatus?) -> Void) {
        let connectedRef = Firestore.firestore().collection(".info").document("connected")
        connectedRef.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot, snapshot.exists, (snapshot.data()?["connected"] as? Bool ?? false) {
                let subscriptionsRef = Firestore.firestore().collection("Subscriptions")
                subscriptionsRef.whereField("iosOriginTransactionId", isEqualTo: originTransactionId).getDocuments { (snapshot, error) in
                    if let snapshot = snapshot, let data = snapshot.documents.first {
                        let labKey = data.documentID
                        completion(labKey == UserSession.current.dataRef ? .linkedCurrent : .linkedAnother)
                    } else {
                        completion(.notLinked)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }

    func updateSubInfo(_ productId: String, transactionId: String, originTransactionId: String, paymentDate: Date, nextPaymentDate: Date) {
        guard let ref = mainRef else { return }
        var data: [String: Any] = [
            "providerId": "ios",
            "iosProductId": productId,
            "iosTransactionId": transactionId,
            "iosOriginTransactionId": originTransactionId.isEmpty ? transactionId : originTransactionId,
            "paymentDate": paymentDate.timeIntervalSince1970,
            "nextPaymentDate": nextPaymentDate.timeIntervalSince1970
        ]
        if let subscriptionId = SubscriptionType(rawValue: productId)?.subscriptionId {
            data["subscriptionId"] = subscriptionId
        }
        ref.collection(Refs.subscription.rawValue).document(UserSession.current.dataRef).setData(data)
        Firestore.firestore().collection("Subscriptions").document(UserSession.current.dataRef).setData(data)
    }

    // MARK: - Logs
    func log(date: Date, object: Refs, action: ActionType, description: String, objectRef: String? = "") {
        if let currentUser = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let logsRef = db.collection(Refs.logs.rawValue).document()
            
            let data: [String: Any] = [
                "timestamp": date.interval as Int,
                "object": object.rawValue as String,
                "action": action.rawValue as String,
                "description": description as String,
                "firebaseRef": logsRef.documentID,
                "objectRef": objectRef ?? ""
            ]
            
            logsRef.setData(data) { error in
                if let error = error {
                    print("LOG: FIRESTORE ERROR - \(error.localizedDescription)!")
                } else {
                    print("Data logged successfully!")
                }
            }
        }
    }
}
