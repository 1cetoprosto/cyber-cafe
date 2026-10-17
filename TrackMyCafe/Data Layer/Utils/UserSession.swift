//
//  UserSession.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Firebase
import FirebaseAuth
import Foundation
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

    // Deprecated: Always true in new architecture
    // public private(set) var hasOnlineVersion: Bool = false

    var employeeRef: String {
        switch role! {
        case .administrator:
            return masterUserRef
        case .waiter, .techMod, .moderator:
            return RequestManager.shared.employees.first { $0.email == userEmail }!.firebaseRef
        }
    }

    static func createSession(id: String, email: String, roleConfig: RoleConfig, rememberUser: Bool)
    {
        UserSession.current.remove()
        UserSession.current.userId = id
        UserSession.current.userEmail = email
        UserSession.current.role = roleConfig.role
        UserSession.current.userRef = roleConfig.userRef
        UserSession.current.dataRef = roleConfig.dataRef
        // TODO: данні раніше бралися із rememberUser
        UserSession.current.rememberUser = true  // rememberUser
        UserSession.current.masterUserRef = roleConfig.dataRef
        // TODO: данні раніше бралися із roleConfig.hasOnlineVersion
        // UserSession.current.hasOnlineVersion = true  // roleConfig.hasOnlineVersion
        UserSession.current.save()

        IAPManager.shared.completeTransactions()
    }

    func restore() -> Bool {
        let chain = Keychain()
        do {
            userId = try chain.getString(KeychainKeys.userId)
            userEmail = try chain.getString(KeychainKeys.userEmail)
            rememberUser =
                try chain.getString(KeychainKeys.userRemember) == DefaultValues.trueString

            useBioAuthUser = try chain.getString(KeychainKeys.useBioUser)
            useBioAuth = try chain.getString(KeychainKeys.useBio) == DefaultValues.trueString

            // Restore session-scoped fields that are not re-fetched on launch.
            if let roleRaw = try chain.getString(KeychainKeys.role),
                let roleValue = Int(roleRaw),
                let restoredRole = Role(rawValue: roleValue)
            {
                role = restoredRole
            }
            userRef = try chain.getString(KeychainKeys.userRef)
            dataRef = try chain.getString(KeychainKeys.dataRef)
            masterUserRef = try chain.getString(KeychainKeys.masterUserRef)

            // hasOnlineVersion = try chain.getString(KeychainKeys.hasOnlineVersion) == DefaultValues.trueString

            // A session is only usable when the RBAC fields the app relies on are
            // present. Sessions persisted by older builds lack these keys and must
            // be rejected so the user lands on the sign-in screen instead of
            // launching with a half-restored session.
            return userId != nil && userEmail != nil && role != nil
                && masterUserRef != nil
        } catch {
            remove()
            return false
        }
    }

    func save() {
        guard rememberUser else { return }
        let chain = Keychain()
        do {
            try chain.set(userId, key: KeychainKeys.userId)
            try chain.set(userEmail, key: KeychainKeys.userEmail)
            try chain.set(
                rememberUser ? DefaultValues.trueString : DefaultValues.falseString,
                key: KeychainKeys.userRemember)
            if let value = useBioAuthUser {
                try chain.set(value, key: KeychainKeys.useBioUser)
            }
            if let value = useBioAuth {
                try chain.set(
                    value ? DefaultValues.trueString : DefaultValues.falseString,
                    key: KeychainKeys.useBio)
                // try chain.set(
                //   hasOnlineVersion ? DefaultValues.trueString : DefaultValues.falseString,
                //   key: KeychainKeys.hasOnlineVersion)
            }
            // Persist session-scoped fields so RBAC works after app relaunch.
            if let role = role {
                try chain.set(String(role.rawValue), key: KeychainKeys.role)
            }
            try chain.set(userRef, key: KeychainKeys.userRef)
            try chain.set(dataRef, key: KeychainKeys.dataRef)
            try chain.set(masterUserRef, key: KeychainKeys.masterUserRef)
        } catch {
            remove()
            AppLogger.forType(UserSession.self).error(
                "Failed to save user session to keychain: \(error.localizedDescription)")
        }
    }

    func remove() {
        let chain = Keychain()
        do {
            try chain.remove(KeychainKeys.userId)
            try chain.remove(KeychainKeys.userEmail)
            try chain.remove(KeychainKeys.userRemember)
            try chain.remove(KeychainKeys.useBioUser)
            try chain.remove(KeychainKeys.useBio)
            try? chain.remove(KeychainKeys.hasOnlineVersion)
            try? chain.remove(KeychainKeys.role)
            try? chain.remove(KeychainKeys.userRef)
            try? chain.remove(KeychainKeys.dataRef)
            try? chain.remove(KeychainKeys.masterUserRef)
        } catch { print(error) }

        userId = nil
        userEmail = nil
        role = nil
        userRef = nil
        dataRef = nil
        rememberUser = false
        masterUserRef = nil
        // hasOnlineVersion = false

        // NotificationManager.removeAllScheduledComments() //TODO: розібратися навіщо це потрібно
    }

    func enableBioAuth(_ enable: Bool) {
        useBioAuthUser = userEmail
        useBioAuth = enable
        UserSession.current.save()
    }

    // public func saveOnline(_ isOn: Bool) {
    //   let chain = Keychain()
    //   do {
    //     hasOnlineVersion = isOn
    //     try chain.set(
    //       hasOnlineVersion ? DefaultValues.trueString : DefaultValues.falseString,
    //       key: KeychainKeys.hasOnlineVersion)
    //   } catch {
    //     //remove()
    //     print(error)
    //   }
    // }

    static func logOut() {
        do {
            try Auth.auth().signOut()
            deleteSession()

            // Removed Online check
            // if UserSession.current.hasOnlineVersion {
            // UserSession.current.saveOnline(false)
            let isValidSession = UserSession.current.restore()
            if isValidSession {
                UserSession.current.remove()
            }
            // }
        } catch {
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
