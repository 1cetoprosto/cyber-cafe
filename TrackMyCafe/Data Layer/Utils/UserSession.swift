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
    
    public private(set) var hasOnlineVersion: Bool = false
    
    var techRef: String {
        switch role! {
            case .administrator:
                return masterUserRef
            case .technician, .techMod, .moderator:
                return RequestManager.shared.technicians.first { $0.email == userEmail }!.firebaseRef
        }
    }
    
    static func createSession(id: String, email: String, roleConfig: RoleConfig, rememberUser: Bool) {
        UserSession.current.remove()
        UserSession.current.userId = id
        UserSession.current.userEmail = email
        UserSession.current.role = roleConfig.role
        UserSession.current.userRef = roleConfig.userRef
        UserSession.current.dataRef = roleConfig.dataRef
        //TODO: данні раніше бралися із rememberUser
        UserSession.current.rememberUser = true // rememberUser
        UserSession.current.masterUserRef = roleConfig.dataRef
        //TODO: данні раніше бралися із roleConfig.hasOnlineVersion
        UserSession.current.hasOnlineVersion = true // roleConfig.hasOnlineVersion
        UserSession.current.save()
        
        IAPManager.shared.completeTransactions()
    }
    
    func restore() -> Bool {
        let chain = Keychain()
        do {
            userId = try chain.getString("KeychainSessionUserId")
            userEmail = try chain.getString("KeychainSessionUserEmail")
            rememberUser = try chain.getString("KeychainSessionUserRemember") == "true"
            
            useBioAuthUser = try chain.getString("KeychainSessionUserUseBioUser")
            useBioAuth = try chain.getString("KeychainSessionUserUseBio") == "true"

            hasOnlineVersion = try chain.getString("KeychainSessionUserHasOnlineVersion") == "true"
            
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
            try chain.set(hasOnlineVersion ? "true" : "false", key: "KeychainSessionUserHasOnlineVersion")
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
            try chain.remove("KeychainSessionUserHasOnlineVersion")
        } catch { print(error)}
        
        userId = nil
        userEmail = nil
        role = nil
        userRef = nil
        dataRef = nil
        rememberUser = false
        masterUserRef = nil
        hasOnlineVersion = false
        
        //NotificationManager.removeAllScheduledComments() //TODO: розібратися навіщо це потрібно
    }
    
    func enableBioAuth(_ enable: Bool) {
        useBioAuthUser = userEmail
        useBioAuth = enable
        UserSession.current.save()
    }

    public func saveOnline(_ isOn: Bool) {
        let chain = Keychain()
        do {
            hasOnlineVersion = isOn
            try chain.set(hasOnlineVersion ? "true" : "false", key: "KeychainSessionUserHasOnlineVersion")
        }
        catch {
            //remove()
            print(error)
        }
    }
    
    static func logOut() {
        do {
            try Auth.auth().signOut()
            deleteSession()
            if UserSession.current.hasOnlineVersion {
                UserSession.current.saveOnline(false)
//                let navigation = UINavigationController(rootViewController: SignInController())
//                navigation.setNavigationBarHidden(true, animated: false)
//                SceneDelegate.shared.set(root: navigation)
//                //logger.log("Deleted Session (Logout) hasOnlineVersion - \(UserSession.current.hasOnlineVersion)")
//                //            if UserSession.current.hasOnlineVersion {
                                let isValidSession = UserSession.current.restore()
                                if isValidSession {
                                    UserSession.current.remove()
                                }
            }
        }
        catch {
            print(error)
        }
    }
    
    static func deleteSession() {
        RequestManager.shared.resetData()
        UserSession.current.remove()
//        let navigation = UINavigationController(rootViewController: MainTabBarController())
//        navigation.setNavigationBarHidden(true, animated: false)
//        //AppDelegate.shared.set(root: navigation)
//        SceneDelegate.shared.set(root: navigation)
    }
}

