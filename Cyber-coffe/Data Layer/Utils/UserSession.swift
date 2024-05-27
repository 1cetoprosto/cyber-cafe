//
//  UserSession.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import Firebase
import FirebaseAuth
import KeychainAccess

struct UserSessionModel {
    let id: String
    let name: String?
    let email: String
    let photo: String?
}

class UserSession {
    
    static let current = UserSession()
    
    var isAuth: Bool {
        return userEmail != nil && Auth.auth().currentUser != nil
    }
    
    var isAdmin: Bool {
        return role! == .administrator
    }
    
    var isModerator: Bool {
        return role! == .moderator
    }
    
    public private(set) var userId: String!
    public private(set) var userEmail: String!
    public private(set) var role: Role!
    public private(set) var userRef: String!
    public private(set) var dataRef: String!
    public private(set) var rememberUser: Bool = false
    
    public private(set) var useBioAuthUser: String?
    public private(set) var useBioAuth: Bool?
    
    public private(set) var masterUserRef: String!
    
    var techRef: String {
        switch role! {
            case .administrator:
                return masterUserRef
            case .technician, .techMod, .moderator:
                return "" //RequestManager.shared.technicians.first { $0.email == userEmail }!.firebaseRef // TODO: розкоментувати
        }
    }
    
    static func createSession(id: String, email: String, roleConfig: RoleConfig, rememberUser: Bool) {
        UserSession.current.remove()
        UserSession.current.userId = id
        UserSession.current.userEmail = email
        UserSession.current.role = roleConfig.role
        UserSession.current.userRef = roleConfig.userRef
        UserSession.current.dataRef = roleConfig.dataRef
        UserSession.current.rememberUser = rememberUser
        UserSession.current.masterUserRef = roleConfig.dataRef
        UserSession.current.save()
        
        //IAPManager.shared.completeTransactions() //TODO: розкоментувати тут щось повязане із покупками
    }
    
    func restore() -> Bool {
        let chain = Keychain()
        do {
            userId = try chain.getString("KeychainSessionUserId")
            userEmail = try chain.getString("KeychainSessionUserEmail")
            rememberUser = try chain.getString("KeychainSessionUserRemember") == "true"
            
            useBioAuthUser = try chain.getString("KeychainSessionUserUseBioUser")
            useBioAuth = try chain.getString("KeychainSessionUserUseBio") == "true"
            return userId != nil && userEmail != nil
        } catch {
            remove()
            return false
        }
    }
    
    func save() {
        guard rememberUser else { return }
         let chain = Keychain()
        do {
            try chain.set(userId, key: "KeychainSessionUserId")
            try chain.set(userEmail, key: "KeychainSessionUserEmail")
            try chain.set(rememberUser ? "true" : "false", key: "KeychainSessionUserRemember")
            if let value = useBioAuthUser {
                try chain.set(value, key: "KeychainSessionUserUseBioUser")
            }
            if let value = useBioAuth {
                try chain.set(value ? "true" : "false", key: "KeychainSessionUserUseBio")
            }
        }
        catch {
            remove()
            print(error)
        }
    }

    func remove() {
        let chain = Keychain()
        do {
            try chain.remove("KeychainSessionUserId")
            try chain.remove("KeychainSessionUserEmail")
            try chain.remove("KeychainSessionUserRemember")
            try chain.remove("KeychainSessionUserUseBioUser")
            try chain.remove("KeychainSessionUserUseBio")
        } catch { print(error)}
        
        userId = nil
        userEmail = nil
        role = nil
        userRef = nil
        dataRef = nil
        rememberUser = false
        masterUserRef = nil
        
        //NotificationManager.removeAllScheduledComments() //TODO: розібратися навіщо це потрібно
    }
    
    func enableBioAuth(_ enable: Bool) {
        useBioAuthUser = userEmail
        useBioAuth = enable
        UserSession.current.save()
    }
    
    static func logOut() {
        do {
            try Auth.auth().signOut()
            deleteSession()
        }
        catch {
            print(error)
        }
    }
    
    static func deleteSession() {
        //RequestManager.shared.resetData() // TODO: розкоментувати
        UserSession.current.remove()
        let navigation = UINavigationController(rootViewController: SignInController())
        navigation.setNavigationBarHidden(true, animated: false)
        //AppDelegate.shared.set(root: navigation)
        SceneDelegate.shared.set(root: navigation)
    }
}
