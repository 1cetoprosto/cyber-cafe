//
//  AuthManager.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 10.08.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class AuthModel {
    private static var sentLinkEmail: String?
    
    enum AuthModelAction {
        case loading(Bool)
        case error(Error?)
        case alert(String, String?, (() -> Void)?)
        case retry(cancel: () -> Void, retry: () -> Void)
        case chooseRole([RoleConfig], (RoleConfig) -> Void)
        case confirmEmail((String) -> Void)
        
        // Ask user to set password
        case success(Bool)
    }
    
    var actionHandler: ((AuthModelAction) -> Void)?
    
    private func send(_ action: AuthModelAction) {
        actionHandler?(action)
    }
    
    private var auth: Auth {
        return Auth.auth()
    }
    
    private var reference: DatabaseReference {
        return Database.database().reference()
    }
    
    func signIn(email: String, password: String, rememberUser: Bool) {
        send(.loading(true))
        auth.signIn(withEmail: email, password: password) {[weak self] (authUser, error) in
            if let user = authUser {
                self?.createUserOrLogin(user.user.uid, user.user.email!, rememberUser)
            } else {
                self?.send(.loading(false))
                self?.send(.error(error))
            }
        }
    }
    
    func signUp(email: String, password: String) {
        send(.loading(true))
        auth.createUser(withEmail: email, password: password) {[weak self] (authUser, error) in
            if let user = authUser {
                self?.createUserOrLogin(user.user.uid, user.user.email!)
            } else {
                self?.send(.loading(false))
                self?.send(.error(error))
            }
        }
    }
    
    func signInWithLink(_ link: String, email: String) {
        send(.loading(true))
        auth.signIn(withEmail: email, link: link) {[weak self] (authUser, error) in
            if let user = authUser {
                self?.createUserOrLogin(user.user.uid, user.user.email!, false, true)
            } else {
                self?.send(.loading(false))
                self?.send(.error(error))
            }
        }
    }
    
    func sendSignInLink(_ email: String) {
        send(.loading(true))
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: Config.associatedDomain)
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        actionCodeSettings.setAndroidPackageName(Config.androidBundle, installIfNotAvailable: true, minimumVersion: Config.androidVersion)
        
        auth.sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) {[weak self] (error) in
            self?.send(.loading(false))
            if let error = error {
                self?.send(.alert(R.string.global.error(),
                                  error.localizedDescription,
                                  nil))
            } else {
                self?.send(.alert(Bundle.displayName,
                                  R.string.auth.sentAuthEmail(),
                                  {
                                    AuthModel.sentLinkEmail = email
                                    self?.send(.success(false))
                }))
            }
        }
    }
    
    func signInWithLink(_ link: String) {
        if let email = AuthModel.sentLinkEmail {
            signInWithLink(link, email: email)
            AuthModel.sentLinkEmail = nil
        } else {
            send(.confirmEmail({[weak self] (email) in
                self?.signInWithLink(link, email: email)
            }))
        }
    }
    
    func signInWithBio() {
        send(.loading(true))
        createUserOrLogin(UserSession.current.userId,
                          UserSession.current.userEmail,
                          UserSession.current.rememberUser)
    }
    
    private func createUserOrLogin(_ id: String, _ email: String, _ rememberUser: Bool = true, _ setPassword: Bool = false) {
        self.send(.loading(false))
        //self.login(id, email, roles.first!, rememberUser)
        let roleConfig = RoleConfig(ref: "", email: email, dataRef: "", userRef: "", role: .administrator, onlineVersion: true)
        self.login(id, email, roleConfig, rememberUser)
        self.send(.success(setPassword))
        //        DatabaseService.getRoles(email) {[weak self] (roles) in // TODO: розкоментувати
        //            if let roles = roles, roles.count > 0 {
//                let userDataKey: String?
//                if roles.count == 1 {
//                    userDataKey = roles.first?.userRef
//                } else {
//                    userDataKey = roles.first(where: { $0.role != .administrator })?.userRef
//                }
//                self?.checkData(userDataKey) { (existUser) in
//                    if existUser {
//                        if roles.count > 1 {
//                            self?.send(.loading(false))
//                            let chooseRoles = roles.filter { $0.role != .administrator }
//                            self?.send(.chooseRole(chooseRoles, { (role) in
//                                self?.login(id, email, role, rememberUser)
//                                self?.send(.success(setPassword))
//                            }))
//                        } else {
//                            self?.send(.loading(false))
//                            self?.login(id, email, roles.first!, rememberUser)
//                            self?.send(.success(setPassword))
//                        }
//                    } else {
//                        self?.createNewUser(roles, id, email) { success in
//                            if success {
//                                if roles.count > 1 {
//                                    let chooseRoles = roles.filter { $0.role != .administrator }
//                                    self?.send(.chooseRole(chooseRoles, { (role) in
//                                        self?.send(.loading(false))
//                                        self?.login(id, email, role, true)
//                                        self?.send(.success(setPassword))
//                                    }))
//                                } else {
//                                    self?.send(.loading(false))
//                                    self?.login(id, email, roles.first!, rememberUser)
//                                    self?.send(.success(setPassword))
//                                }
//                            } else {
//                                self?.send(.loading(false))
//                                self?.send(.retry(cancel: {
//                                    self?.logOut()
//                                }, retry: {
//                                    self?.createUserOrLogin(id, email, rememberUser, setPassword)
//                                }))
//                            }
//                        }
//                    }
//                }
//            } else {
//                self?.createNewLab(id, email)  {[weak self] (role, success) in
//                    if success, let role = role {
//                        self?.send(.loading(false))
//                        self?.login(id, email, role, rememberUser)
//                        self?.send(.success(setPassword))
//                    } else {
//                        self?.send(.loading(false))
//                        self?.send(.retry(cancel: {
//                            self?.logOut()
//                        }, retry: {
//                            self?.createUserOrLogin(id, email, rememberUser, setPassword)
//                        }))
//                    }
//                }
//            }
//            
//        }
    }
    
    private func login(_ id: String, _ email: String, _ role: RoleConfig, _ rememberUser: Bool) {
        UserSession.createSession(id: id, email: email, roleConfig: role, rememberUser: rememberUser)
        //RequestManager.shared.startListening() // TODO: розкоментувати
    }
    
    private func logOut() {
        do {
            try auth.signOut()
            UserSession.current.remove()
            //RequestManager.shared.resetData() // TODO: розкоментувати
        } catch {
            print(error)
        }
    }
    
    private func createNewUser(_ roles: [RoleConfig], _ id: String, _ email: String, _ completion: @escaping (Bool) -> Void) {
        guard let newUserRef = reference.child(Refs.users.rawValue).childByAutoId().key,
              let userData = userData(newUserRef, id, email) else {
            completion(false)
            return
        }
        
        var updateNodes = [
            "\(Refs.users.rawValue)/\(newUserRef)": userData
        ] as [String: Any]
        
        roles.forEach { role in
            updateNodes["\(Refs.roles.rawValue)/\(role.firebaseRef)/userRef"] = newUserRef
            role.userRef = newUserRef
        }
        
        Database.database().reference().updateChildValues(updateNodes) { (error, ref) in
            completion(error == nil)
        }
    }
    
    private func createNewLab(_ id: String, _ email: String, _ completion: @escaping (RoleConfig?, Bool) -> Void) {
        guard let userKey = reference.child(Refs.users.rawValue).childByAutoId().key,
            let userData = userData(userKey, id, email) else {
            completion(nil, false)
            return
        }
        
        guard let roleKey = reference.child(Refs.roles.rawValue).childByAutoId().key else { return }
        let role = RoleConfig(ref: roleKey, email: email, dataRef: userKey, userRef: userKey, role: Role.administrator, onlineVersion: false)
        
        let updateNodes = [
            "\(Refs.users.rawValue)/\(userKey)": userData,
            "\(Refs.roles.rawValue)/\(roleKey)": role.forDatabase(),
            ] as [String : Any]
        
        Database.database().reference().updateChildValues(updateNodes) { (error, ref) in
            completion(role, error == nil)
        }
    }
    
    private func userData(_ userKey: String, _ id: String, _ email: String) -> [String: Any]? {
        let elementRef = reference.child(Refs.users.rawValue).child(userKey).child("ElementTypes")
        guard let elementOneKey = elementRef.childByAutoId().key,
            let elementTwoKey = elementRef.childByAutoId().key,
            let elementThreeKey = elementRef.childByAutoId().key else { return nil}
        
        var userValue: [String : Any] = [
            "uid": id,
            "firebaseRef": userKey,
            "createdDate": Date().interval,
            "updatedDate": Date().interval,
            "firstName": "Admin",
            "middleName": "",
            "lastName": "",
            "email": email.trimmed.lowercased(),
            "phone": "",
            "address": "",
            "comment": "",
            "avatarUrl": "",
            "avatarThumbnailUrl": "",
        ]
//        userValue["ElementTypes"] = [
//            elementOneKey: ElementType(ref: elementOneKey, title: R.string.global.veener(), color: "#33CC00").forDatabase(),
//            elementTwoKey: ElementType(ref: elementTwoKey, title: R.string.global.denture(), color: "#CC3300").forDatabase(),
//            elementThreeKey: ElementType(ref: elementThreeKey, title: R.string.global.metalCeramic(), color: "#0099CC").forDatabase()
//        ]
        userValue["Settings"] = Settings(currencyName: "Dollar", currencySymbol: "$").forDatabase()
        
        return userValue
    }
    
    private func checkData(_ key: String?, completion: @escaping (Bool) -> Void) {
        guard let key = key else {
            completion(false)
            return
        }
        Database.database().reference().child(Refs.users.rawValue).child(key).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot.exists())
        }
    }
}
