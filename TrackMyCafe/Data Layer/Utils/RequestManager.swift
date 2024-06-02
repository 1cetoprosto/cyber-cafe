////
////  RequestManager.swift
////  Cyber-coffe
////
////  Created by Леонід Квіт on 27.04.2024.
////
//
//import Foundation
//import Firebase
//import FirebaseAuth
//import FirebaseDatabase
//import FirebaseStorage
//
//enum SubscriptionCostLinkStatus {
//    case notLinked
//    case linkedCurrent
//    case linkedAnother
//}
//
//class RequestManager: NSObject {
//    
//    static let shared = RequestManager()
//    var ref: DatabaseReference!
//    var mainRef: DatabaseReference!
//    
//    
//    //TODO: - Add observer
//    private var _userAvatarPath: String?
//    var userAvatarPath: String? {
//        if UserSession.current.isAdmin { return admin.avatarThumbnailUrl }
//        return RequestManager.shared.technicians.first { $0.firebaseRef == UserSession.current.techRef }?.avatarThumbnailUrl
//    }
//    
//    private var _orders = [Order]()
//    var orders: [Order] {
//        get {
//            return _orders.filter { $0.enabled }
//        }
//        set {
//            _orders = newValue
//        }
//    }
//    
//    var admin = Admin()
//    var doctors = [Doctor]()
//    var enabledDoctors: [Doctor] {
//        return doctors.filter { $0.enabled }
//    }
//    
//    var technicians = [Technician]()
//    var cadcams = [CadCam]()
//    var casters = [Caster]()
//    var mainElements = [MainElement]()
//    var extraElements = [ExtraElement]()
//    var elementsTypes = [ElementType]()
//    var comments = [Comment]()
//    var logs = [Log]()
//    var users = [User]()
//    var roles = [RoleConfig]()
//    var settings: Settings?
//    var subscription: Subscription?
//    
//    override init() {
//        ref = Database.database().reference()
//        super.init()
//        admin.firebaseRef = UserSession.current.masterUserRef
//    }
//    
//    // MARK: - Listeners
//    
//    func resetData() {
//        orders = []
//        doctors = []
//        technicians = []
//        cadcams = []
//        casters = []
//        mainElements = []
//        extraElements = []
//        elementsTypes = []
//        comments = []
//        logs = []
//        users = []
//        roles = []
//        settings = nil
//    }
//    
//    func startListening() {
//        if Auth.auth().currentUser != nil {
//            if let masterRef = UserSession.current.masterUserRef {
//                mainRef = ref.child(Refs.users.rawValue).child(masterRef)
//            }
//            self.listenTo(.doctors)
//            self.listenTo(.technicians)
//            self.listenTo(.mainElements)
//            self.listenTo(.extraElements)
//            self.listenTo(.elementTypes)
//            self.listenTo(.comments)
//            self.listenTo(.logs)
//            self.listenToCadcams()
//            self.listenToCasters()
//            self.listenToSettings()
//            self.listenToSubscription()
//            self.listenTo(.orders)
//            self.listenToAdmin()
//        } else {
//            self.ref.removeAllObservers()
//        }
//    }
//    
//    // MARK: - Doctors
//    
//    func listenTo(_ refId: Refs) {
//        if Auth.auth().currentUser != nil {
//            
//            var items: [AnyObject] = []
//            var notifName = NSNotification.Name("")
//            
//            switch refId {
//            case .orders:
//                notifName = .ordersInfoReload
//            case .doctors:
//                notifName = .doctorsInfoReload
//            case .technicians:
//                notifName = .techniciansInfoReload
//            case .mainElements:
//                notifName = .mainElementsInfoReload
//            case .extraElements:
//                notifName = .extraElementsInfoReload
//            case .elementTypes:
//                notifName = .elementTypesInfoReload
//            case .comments:
//                notifName = .commentsInfoReload
//                case .logs:
//                notifName = .logsInfoReload
//            default:
//                print("should not be here")
//            }
//            
//            mainRef.child(refId.rawValue).observe(.childChanged) { (snapshot) in
//                print(snapshot)
//            }
//            
//            mainRef.child(refId.rawValue).observe(DataEventType.value, with: { (snapshot) in
//                
//                let objects = snapshot.children.allObjects as? [DataSnapshot] ?? []
////                print("✅ \(refId.rawValue) objects = \(objects)")
//                
//                items.removeAll()
//                
//                if objects.count > 0 {
//                    for obj in objects {
//                        guard let item = self.map(obj.value as! [String : AnyObject], refId) else { continue }
//                        items.append(item)
//                    }
//                    
//                    switch refId {
//                    case .orders:
//                        self.orders = items as! [Order]
//                    case .doctors:
//                        self.doctors = items as! [Doctor]
//                    case .technicians:
//                        self.technicians = items as! [Technician]
//                    case .mainElements:
//                        self.mainElements = items as! [MainElement]
//                    case .extraElements:
//                        self.extraElements = items as! [ExtraElement]
//                    case .elementTypes:
//                        self.elementsTypes = items as! [ElementType]
//                    case .comments:
//                        self.comments = items as! [Comment]
//                        let userScheduledComments = RequestManager.shared.comments.filter { $0.alarmDate != nil && $0.techinicianKey == UserSession.current.techRef }
//                        if userScheduledComments.isNotEmpty {
//                            NotificationManager.processComments(userScheduledComments)
//                        } else {
//                            NotificationManager.removeAllScheduledComments()
//                        }
//                    case .logs:
//                        self.logs = items as! [Log]
//                    default:
//                        print(items)
//                    }
//                    
//                    NotificationCenter.default.post(name: notifName, object: nil)
//                }
//            }) { (error) in
//                guard UserSession.current.userId != nil else { return }
//                if let root = UIApplication.shared.keyWindow!.rootViewController {
//                    root.showAlert(R.string.global.error(), body: error.localizedDescription)
//                }
//            }
//        }
//    }
//    
//    func map(_ object: [String : AnyObject], _ refId: Refs) -> AnyObject? {
//        if refId == .doctors {
//            return Doctor(object)
//        }
//        else if refId == .technicians {
//            return Technician(object)
//        }
//        else if refId == .mainElements {
//            return MainElement(object)
//        }
//        else if refId == .extraElements {
//            return ExtraElement(object)
//        }
//        else if refId == .elementTypes {
//            return ElementType(object)
//        }
//        else if refId == .orders {
//            return Order(object)
//        }
//        else if refId == .comments {
//            return Comment(object)
//        }
//        else if refId == .logs {
//            let element = Log(date: Date(timeIntervalSince1970: object["timestamp"] as! Double),
//                              object: Refs(rawValue: object["object"] as! String)!,
//                              action: ActionType(rawValue: object["action"] as! String)!,
//                              description: object["description"] as! String)
//            element.firebaseRef = object["firebaseRef"] as? String
//            element.objectRef = object["objectRef"] as? String
//            return element
//        }
//        
//        return nil
//    }
//    
//    // MARK: - CadCams
//    
//    func listenToCadcams() {
//        if Auth.auth().currentUser != nil {
//            mainRef.child(Refs.cadcams.rawValue).observe(DataEventType.value, with: { (snapshot) in
//                let objects = snapshot.children.allObjects as? [DataSnapshot] ?? []
//                self.cadcams.removeAll()
//                
//                if objects.count > 0 {
//                    for obj in objects {
//                        let item = self.mapCadcam(obj.value as! [String : AnyObject])
//                        self.cadcams.append(item)
//                    }
//                    
//                    self.cadcams = self.cadcams.filter({$0.enabled == true})
//                    NotificationCenter.default.post(name: .cadcamsInfoReload, object: nil)
//                }
//            }) { (error) in
//                guard UserSession.current.userId != nil else { return }
//                if let root = UIApplication.shared.keyWindow!.rootViewController {
//                    root.showAlert(R.string.global.error(), body: error.localizedDescription)
//                }
//            }
//        }
//    }
//    
//    func mapCadcam(_ object: [String : AnyObject]) -> CadCam {
//        return CadCam(object)!
//    }
//    
//    // MARK: - Casters
//    
//    func listenToCasters() {
//        if Auth.auth().currentUser != nil {
//            mainRef.child(Refs.casters.rawValue).observe(DataEventType.value, with: { (snapshot) in
//                let objects = snapshot.children.allObjects as? [DataSnapshot] ?? []
//                
//                self.casters.removeAll()
//                
//                if objects.count > 0 {
//                    for obj in objects {
//                        let item = self.mapCaster(obj.value as! [String : AnyObject])
//                        self.casters.append(item)
//                    }
//                    
//                    self.casters = self.casters.filter({ $0.enabled == true })
//                    NotificationCenter.default.post(name: .castersInfoReload, object: nil)
//                }
//            }) { (error) in
//                guard UserSession.current.userId != nil else { return }
//                if let root = UIApplication.shared.keyWindow!.rootViewController {
//                    root.showAlert(R.string.global.error(), body: error.localizedDescription)
//                }
//            }
//        }
//    }
//    
//    func mapCaster(_ object: [String : AnyObject]) -> Caster {
//        return Caster(object)!
//    }
//    
//    // MARK: - Settings
//    
//    func listenToSettings() {
//        if Auth.auth().currentUser != nil {
//            mainRef.child(Refs.settings.rawValue).observe(DataEventType.value, with: { (snapshot) in
//                let object = snapshot.value as? [String: AnyObject] ?? [:]
//                print("✅ Settings object = \(object)")
//                
//                if !object.isEmpty {
//                    self.settings = Settings(object)
//                    NotificationCenter.default.post(name: .settingsInfoReload, object: nil)
//                }
//                else {
//                    self.settings = Settings()
//                }
//            }) { (error) in
//                guard UserSession.current.userId != nil else { return }
//                if let root = UIApplication.shared.keyWindow!.rootViewController {
//                    root.showAlert(R.string.global.error(), body: error.localizedDescription)
//                }
//            }
//        }
//    }
//    
//    func listenToAdmin() {
//        mainRef.child("email").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.email != value {
//                self?.admin.email = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("firstName").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.firstName != value {
//                self?.admin.firstName = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("lastName").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.lastName != value {
//                self?.admin.lastName = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("middleName").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.middleName != value {
//                self?.admin.middleName = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("phone").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.phone != value {
//                self?.admin.phone = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("address").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.address != value {
//                self?.admin.address = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("avatarThumbnailUrl").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.avatarThumbnailUrl != value {
//                self?.admin.avatarThumbnailUrl = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("avatarUrl").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.avatarUrl != value {
//                self?.admin.avatarUrl = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//        mainRef.child("comment").observe(.value, with: {[weak self] (snapshot) in
//            guard let value = (snapshot.value as? String)?.nilIfEmpty else { return }
//            if self?.admin.comment != value {
//                self?.admin.comment = value
//                NotificationCenter.default.post(name: .adminInfoReload, object: nil)
//            }
//        })
//    }
//    
//    
//    func listenToSubscription() {
//        if Auth.auth().currentUser != nil {
//            mainRef.child(Refs.subscription.rawValue).observe(.value) { (snapshot) in
//                let object = snapshot.value as? [String: AnyObject] ?? [:]
//                if !object.isEmpty {
//                    self.subscription = Subscription(object)
//                } else {
//                    self.subscription = Subscription()
//                }
//                IAPManager.shared.updateInfo(self.subscription!)
//                NotificationCenter.default.post(name: .subscriptionInfoReload, object: nil)
//            }
//        }
//    }
//    
//    func getSubscriptionInfo(_ completion: @escaping (Subscription) -> Void) {
//        guard Auth.auth().currentUser != nil else {
//            completion(Subscription())
//            return
//        }
//        mainRef.child(Refs.subscription.rawValue).observeSingleEvent(of: .value) { (snapshot) in
//            let object = snapshot.value as? [String: AnyObject] ?? [:]
//            if !object.isEmpty {
//                completion(Subscription(object))
//            } else {
//                completion(Subscription())
//            }
//        }
//    }
//    
//    func isSubscriptionCostLinkedToAccount(_ originTransactionId: String, completion: @escaping (SubscriptionCostLinkStatus?) -> Void) {
//        Database.database().reference(withPath: ".info/connected").observe(.value, with: { snapshot in
//            if snapshot.value as? Bool ?? false {
//                Database.database().reference().child("Subscriptions").queryOrdered(byChild: "iosOriginTransactionId").queryEqual(toValue: originTransactionId).observeSingleEvent(of: .value) { (snapshot) in
//                    if let data = snapshot.value as? [String: Any], let labKey = data.keys.first {
//                        completion(labKey == UserSession.current.dataRef ? .linkedCurrent : .linkedAnother)
//                    } else {
//                        completion(.notLinked)
//                    }
//                }
//            } else {
//                completion(nil)
//            }
//        })
//    }
//    
//    func updateSubInfo(_ productId: String, transactionId: String, originTransactionId: String, paymentDate: Date, nextPaymentDate: Date) {
//        guard let ref = mainRef else { return }
//        var data: [String: Any] = [
//            "providerId": "ios",
//            "iosProductId": productId,
//            "iosTransactionId": transactionId,
//            "iosOriginTransactionId": originTransactionId.nilIfEmpty ?? transactionId,
//            "paymentDate": paymentDate.interval,
//            "nextPaymentDate": nextPaymentDate.interval
//        ]
//        if let subscriptionId = SubscriptionType(rawValue: productId)?.subscriptionId {
//            data["subscriptionId"] = subscriptionId
//        }
//        ref.child(Refs.subscription.rawValue).updateChildValues(data)
//        Database.database().reference().child("Subscriptions").child(UserSession.current.dataRef).setValue(data)
//    }
//    
//    // MARK: - Logs
//    func log(date: Date, object: Refs, action: ActionType, description: String, objectRef: String? = "") {
//        if Auth.auth().currentUser != nil && mainRef != nil {
//            
//            let itemRef = mainRef.child(Refs.logs.rawValue).childByAutoId()
//            let dict = ["timestamp": date.interval as Int,
//                        "object": object.rawValue as String,
//                        "action": action.rawValue as String,
//                        "description": description as String,
//                        "firebaseRef": itemRef.key!,
//                        "objectRef": objectRef!] as [String : Any]
//            
//            itemRef.setValue(dict) {
//                (error:Error?, ref:DatabaseReference) in
//                if let error = error {
//                    print("LOG: FIREBASE ERROR - \(error)!")
//                } else {
//                    print("Data logged successfully!")
//                }
//            }
//        }
//    }
//}
