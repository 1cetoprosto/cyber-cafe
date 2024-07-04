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
        FirestoreDatabaseService.getRoles(email) { [weak self] (roles) in
            if let roles = roles, !roles.isEmpty {
                self?.handleExistingRoles(roles, id: id, email: email, rememberUser: rememberUser, setPassword: setPassword)
            } else {
                self?.createNewUserOrCafe(nil, id, email, rememberUser, setPassword)
            }
        }
    }

    private func handleExistingRoles(_ roles: [RoleConfig], id: String, email: String, rememberUser: Bool, setPassword: Bool) {
        let userDataKey = roles.first?.userRef

        self.checkData(userDataKey) { [weak self] (existUser) in
            if existUser {
                self?.processExistingUserRoles(roles, id: id, email: email, rememberUser: rememberUser, setPassword: setPassword)
            } else {
                self?.createNewUserOrCafe(roles, id, email, rememberUser, setPassword)
            }
        }
    }

    private func processExistingUserRoles(_ roles: [RoleConfig], id: String, email: String, rememberUser: Bool, setPassword: Bool) {
        if roles.count > 1 {
            self.send(.loading(false))
            let chooseRoles = roles.filter { $0.role != .administrator }
            self.send(.chooseRole(chooseRoles, { [weak self] (role) in
                self?.login(id, email, role, rememberUser)
                self?.send(.success(setPassword))
            }))
        } else {
            self.send(.loading(false))
            self.login(id, email, roles.first!, rememberUser)
            self.send(.success(setPassword))
        }
    }

    private func createNewUserOrCafe(_ roles: [RoleConfig]?, _ id: String, _ email: String, _ rememberUser: Bool, _ setPassword: Bool) {
        if let roles = roles, !roles.isEmpty {
            FirestoreDatabaseService.shared.createNewUser(roles, id, email) { [weak self] success in
                if success {
                    self?.handleNewUserRoles(roles, id: id, email: email, rememberUser: rememberUser, setPassword: setPassword)
                } else {
                    self?.handleRetry(id: id, email: email, rememberUser: rememberUser, setPassword: setPassword)
                }
            }
        } else {
            FirestoreDatabaseService.shared.createNewCafe(id, email) { [weak self] (role, success) in
                if success, let role = role {
                    self?.send(.loading(false))
                    self?.login(id, email, role, rememberUser)
                    self?.send(.success(setPassword))
                } else {
                    self?.handleRetry(id: id, email: email, rememberUser: rememberUser, setPassword: setPassword)
                }
            }
        }
    }

    private func handleNewUserRoles(_ roles: [RoleConfig], id: String, email: String, rememberUser: Bool, setPassword: Bool) {
        if roles.count > 1 {
            let chooseRoles = roles.filter { $0.role != .administrator }
            self.send(.chooseRole(chooseRoles, { [weak self] (role) in
                self?.send(.loading(false))
                self?.login(id, email, role, true)
                self?.send(.success(setPassword))
            }))
        } else {
            self.send(.loading(false))
            self.login(id, email, roles.first!, rememberUser)
            self.send(.success(setPassword))
        }
    }

    private func handleRetry(id: String, email: String, rememberUser: Bool, setPassword: Bool) {
        self.send(.loading(false))
        self.send(.retry(cancel: {
            self.logOut()
        }, retry: {
            self.createUserOrLogin(id, email, rememberUser, setPassword)
        }))
    }

    private func checkData(_ key: String?, completion: @escaping (Bool) -> Void) {
        guard let key = key else {
            completion(false)
            return
        }
        FirestoreDatabaseService.shared.checkData(key) { exists in
            completion(exists)
        }
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
    
//    private func createNewUser(_ roles: [RoleConfig], _ id: String, _ email: String, _ completion: @escaping (Bool) -> Void) {
//        guard let newUserRef = reference.child(Refs.users.rawValue).childByAutoId().key,
//              let userData = userData(newUserRef, id, email) else {
//            completion(false)
//            return
//        }
//        
//        var updateNodes = [
//            "\(Refs.users.rawValue)/\(newUserRef)": userData
//        ] as [String: Any]
//        
//        roles.forEach { role in
//            updateNodes["\(Refs.roles.rawValue)/\(role.firebaseRef)/userRef"] = newUserRef
//            role.userRef = newUserRef
//        }
//        
//        Database.database().reference().updateChildValues(updateNodes) { (error, ref) in
//            completion(error == nil)
//        }
//    }
    
//    private func createNewLab(_ id: String, _ email: String, _ completion: @escaping (RoleConfig?, Bool) -> Void) {
//        guard let userKey = reference.child(Refs.users.rawValue).childByAutoId().key,
//            let userData = userData(userKey, id, email) else {
//            completion(nil, false)
//            return
//        }
//        
//        guard let roleKey = reference.child(Refs.roles.rawValue).childByAutoId().key else { return }
//        let role = RoleConfig(ref: roleKey, email: email, dataRef: userKey, userRef: userKey, role: Role.administrator, onlineVersion: true)
//        
//        let updateNodes = [
//            "\(Refs.users.rawValue)/\(userKey)": userData,
//            "\(Refs.roles.rawValue)/\(roleKey)": role.forDatabase(),
//            ] as [String : Any]
//        
//        Database.database().reference().updateChildValues(updateNodes) { (error, ref) in
//            completion(role, error == nil)
//        }
//    }
    
//    private func checkData(_ key: String?, completion: @escaping (Bool) -> Void) {
//        guard let key = key else {
//            completion(false)
//            return
//        }
//        Database.database().reference().child(Refs.users.rawValue).child(key).observeSingleEvent(of: .value) { (snapshot) in
//            completion(snapshot.exists())
//        }
//    }
//    private func checkData(_ key: String?, completion: @escaping (Bool) -> Void) {
//        FirestoreDatabaseService.shared.checkData(key) { exists in
//            completion(exists)
//        }
//    }
}
