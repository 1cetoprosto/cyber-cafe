//
//  AuthManager.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 10.08.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import Foundation

class AuthModel {
    private static var sentLinkEmail: String?
    private static let pendingEmailLinkStorageKey = "AuthModel.pendingEmailLinkEmail"
    private static let emailLinkQueryItemName = "email"

    static func pendingEmailLinkEmail() -> String? {
        sentLinkEmail ?? UserDefaults.standard.string(forKey: pendingEmailLinkStorageKey)
    }

    static func emailLinkContinueURL(for email: String) -> URL? {
        let normalizedEmail = email.trimmed.lowercased()
        var components = URLComponents(string: Config.associatedDomain)
        let basePath =
            components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        let emailPath = "email-link/\(normalizedEmail)"
        components?.path = basePath.isEmpty ? "/\(emailPath)" : "/\(basePath)/\(emailPath)"
        components?.queryItems = [
            URLQueryItem(name: emailLinkQueryItemName, value: normalizedEmail)
        ]
        return components?.url
    }

    static func resolvedPendingEmailLinkEmail(from link: String? = nil) -> String? {
        if let storedEmail = pendingEmailLinkEmail()?.trimmed.lowercased(),
            storedEmail.isValid(regex: .email)
        {
            return storedEmail
        }

        guard let link, let extractedEmail = extractEmail(from: link) else {
            return nil
        }

        rememberPendingEmailLinkEmail(extractedEmail)
        return extractedEmail
    }

    private static func storePendingEmailLinkEmail(_ email: String?) {
        sentLinkEmail = email
        if let email {
            UserDefaults.standard.set(email, forKey: pendingEmailLinkStorageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingEmailLinkStorageKey)
        }
    }

    static func clearPendingEmailLinkState() {
        storePendingEmailLinkEmail(nil)
    }

    static func rememberPendingEmailLinkEmail(_ email: String) {
        storePendingEmailLinkEmail(email.trimmed.lowercased())
    }

    private static func extractEmail(from link: String) -> String? {
        guard let components = URLComponents(string: link) else { return nil }

        if let email = components.queryItems?
            .first(where: { $0.name.caseInsensitiveCompare(emailLinkQueryItemName) == .orderedSame }
            )?
            .value?
            .trimmed
            .lowercased(),
            email.isValid(regex: .email)
        {
            return email
        }

        let nestedURLKeys = ["continueUrl", "continueURL"]
        for key in nestedURLKeys {
            guard
                let nestedValue = components.queryItems?
                    .first(where: { $0.name.caseInsensitiveCompare(key) == .orderedSame })?.value
            else {
                continue
            }

            if let nestedEmail = extractEmail(from: nestedValue) {
                return nestedEmail
            }

            if let decodedNestedValue = nestedValue.removingPercentEncoding,
                let nestedEmail = extractEmail(from: decodedNestedValue)
            {
                return nestedEmail
            }
        }

        let candidates = [link, link.removingPercentEncoding].compactMap { $0 }
        for candidate in candidates {
            if let detectedEmail = firstEmailMatch(in: candidate) {
                return detectedEmail
            }
        }

        return nil
    }

    private static func firstEmailMatch(in text: String) -> String? {
        let pattern = #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#
        guard
            let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            )
        else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
            let matchRange = Range(match.range, in: text)
        else {
            return nil
        }

        let email = String(text[matchRange]).trimmed.lowercased()
        return email.isValid(regex: .email) ? email : nil
    }

    enum AuthModelAction {
        case loading(Bool)
        case error(Error?)
        case alert(String, String?, (() -> Void)?)
        case retry(error: String?, cancel: () -> Void, retry: () -> Void)
        case chooseRole([RoleConfig], (RoleConfig) -> Void)
        case confirmEmail((String) -> Void)

        // Ask user to set password
        case success(Bool)
    }

    var actionHandler: ((AuthModelAction) -> Void)?

    private func send(_ action: AuthModelAction) {
        if Thread.isMainThread {
            actionHandler?(action)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.actionHandler?(action)
            }
        }
    }

    private var auth: Auth {
        return Auth.auth()
    }

    private var reference: DatabaseReference {
        return Database.database().reference()
    }

    func signIn(email: String, password: String, rememberUser: Bool) {
        send(.loading(true))
        auth.signIn(withEmail: email, password: password) { [weak self] (authUser, error) in
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
        auth.createUser(withEmail: email, password: password) { [weak self] (authUser, error) in
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
        let normalizedEmail = email.trimmed.lowercased()
        auth.signIn(withEmail: normalizedEmail, link: link) { [weak self] (authUser, error) in
            if let user = authUser {
                AuthModel.clearPendingEmailLinkState()
                self?.createUserOrLogin(user.user.uid, user.user.email!, false, true)
            } else {
                self?.send(.loading(false))
                self?.send(.error(error))
            }
        }
    }

    func sendSignInLink(_ email: String) {
        send(.loading(true))
        let normalizedEmail = email.trimmed.lowercased()
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = AuthModel.emailLinkContinueURL(for: normalizedEmail)
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        actionCodeSettings.setAndroidPackageName(
            Config.androidBundle, installIfNotAvailable: true, minimumVersion: Config.androidVersion
        )

        auth.sendSignInLink(toEmail: normalizedEmail, actionCodeSettings: actionCodeSettings) {
            [weak self] (error) in
            self?.send(.loading(false))
            if let error = error {
                self?.send(
                    .alert(
                        R.string.global.error(),
                        error.localizedDescription,
                        nil))
            } else {
                self?.send(
                    .alert(
                        Bundle.displayName,
                        R.string.auth.sentAuthEmail(),
                        {
                            AuthModel.storePendingEmailLinkEmail(normalizedEmail)
                            self?.send(.success(false))
                        }))
            }
        }
    }

    func sendPasswordReset(_ email: String) {
        send(.loading(true))
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            self?.send(.loading(false))
            if let error {
                self?.send(.alert(R.string.global.error(), error.localizedDescription, nil))
            } else {
                self?.send(
                    .alert(
                        Bundle.displayName, R.string.auth.sentResetEmail(),
                        {
                            self?.send(.success(false))
                        }))
            }
        }
    }

    func signInWithLink(_ link: String) {
        if let email = AuthModel.resolvedPendingEmailLinkEmail(from: link) {
            signInWithLink(link, email: email)
        } else {
            send(
                .confirmEmail({ [weak self] (email) in
                    self?.signInWithLink(link, email: email)
                }))
        }
    }

    func signInWithBio() {
        send(.loading(true))
        createUserOrLogin(
            UserSession.current.userId,
            UserSession.current.userEmail,
            UserSession.current.rememberUser)
    }

    private func createUserOrLogin(
        _ id: String, _ email: String, _ rememberUser: Bool = true, _ setPassword: Bool = false
    ) {
        Task { [weak self] in
            guard let self else { return }
            let roles = await FirestoreDatabaseService.getRoles(email)
            if let roles = roles, !roles.isEmpty {
                self.handleExistingRoles(
                    roles, id: id, email: email, rememberUser: rememberUser,
                    setPassword: setPassword)
            } else {
                self.createNewUserOrCafe(nil, id, email, rememberUser, setPassword)
            }
        }
    }

    private func handleExistingRoles(
        _ roles: [RoleConfig], id: String, email: String, rememberUser: Bool, setPassword: Bool
    ) {
        let userDataKey = roles.first?.userRef

        Task { [weak self] in
            guard let self else { return }
            let existUser = await self.checkData(userDataKey)
            if existUser {
                self.processExistingUserRoles(
                    roles, id: id, email: email, rememberUser: rememberUser,
                    setPassword: setPassword)
            } else {
                self.createNewUserOrCafe(roles, id, email, rememberUser, setPassword)
            }
        }
    }

    private func processExistingUserRoles(
        _ roles: [RoleConfig], id: String, email: String, rememberUser: Bool, setPassword: Bool
    ) {
        if roles.count > 1 {
            self.send(.loading(false))
            let chooseRoles = roles.filter { $0.role != .administrator && $0.role != .techMod }
            self.send(
                .chooseRole(
                    chooseRoles,
                    { [weak self] (role) in
                        self?.login(id, email, role, rememberUser)
                        self?.send(.success(setPassword))
                    }))
        } else {
            self.send(.loading(false))
            self.login(id, email, roles.first!, rememberUser)
            self.send(.success(setPassword))
        }
    }

    private func createNewUserOrCafe(
        _ roles: [RoleConfig]?, _ id: String, _ email: String, _ rememberUser: Bool,
        _ setPassword: Bool
    ) {
        Task { [weak self] in
            guard let self else { return }
            if let roles = roles, !roles.isEmpty {
                do {
                    try await FirestoreDatabaseService.shared.createNewUser(roles, id, email)
                    self.handleNewUserRoles(
                        roles, id: id, email: email, rememberUser: rememberUser,
                        setPassword: setPassword)
                } catch {
                    self.handleRetry(
                        error: error.localizedDescription, id: id, email: email,
                        rememberUser: rememberUser, setPassword: setPassword)
                }
            } else {
                do {
                    let role = try await FirestoreDatabaseService.shared.createNewCafe(id, email)
                    self.send(.loading(false))
                    self.login(id, email, role, rememberUser)
                    self.send(.success(setPassword))
                } catch {
                    self.handleRetry(
                        error: error.localizedDescription, id: id, email: email,
                        rememberUser: rememberUser, setPassword: setPassword)
                }
            }
        }
    }

    private func handleNewUserRoles(
        _ roles: [RoleConfig], id: String, email: String, rememberUser: Bool, setPassword: Bool
    ) {
        if roles.count > 1 {
            let chooseRoles = roles.filter { $0.role != .administrator && $0.role != .techMod }
            self.send(
                .chooseRole(
                    chooseRoles,
                    { [weak self] (role) in
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

    private func handleRetry(
        error: String? = nil, id: String, email: String, rememberUser: Bool, setPassword: Bool
    ) {
        self.send(.loading(false))
        self.send(
            .retry(
                error: error,
                cancel: {
                    self.logOut()
                },
                retry: {
                    self.createUserOrLogin(id, email, rememberUser, setPassword)
                }))
    }

    private func checkData(_ key: String?) async -> Bool {
        guard let key = key else { return false }
        return await FirestoreDatabaseService.shared.checkData(key)
    }

    private func login(_ id: String, _ email: String, _ role: RoleConfig, _ rememberUser: Bool) {
        UserSession.createSession(
            id: id, email: email, roleConfig: role, rememberUser: rememberUser)
        RequestManager.shared.startListening()
    }

    private func logOut() {
        do {
            try auth.signOut()
            UserSession.current.remove()
            RequestManager.shared.resetData()
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
