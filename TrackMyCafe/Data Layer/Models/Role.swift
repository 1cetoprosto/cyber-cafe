//
//  Role.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation

enum Role: Int {
    case administrator = 0
    case moderator
    case technician
    case techMod
    
    var name: String {
        switch self {
            case .administrator:
                return R.string.global.roleAdmin()
            case .moderator:
                return R.string.global.roleModerator()
            case .technician:
                return R.string.global.roleTechnician()
            case .techMod:
                return R.string.global.roleTechMod()
        }
    }
}

class RoleConfig: CustomStringConvertible {
    
    var timestamp: Date
    var firebaseRef: String
    var email: String
    var dataRef: String
    var userRef: String
    var role: Role
    let hasOnlineVersion: Bool
    
    init(ref: String, email: String, dataRef: String, userRef: String, role: Role, onlineVersion: Bool) {
        self.timestamp = Date()
        self.email = email
        self.dataRef = dataRef
        self.userRef = userRef
        self.role = role
        self.firebaseRef = ref
        self.hasOnlineVersion = onlineVersion
    }
    
    init?(_ data: [String: Any]) {
        guard
            let time = data["timestamp"] as? Double,
            let email = data["email"] as? String,
            let dataRef = data["dataRef"] as? String,
            let userRef = data["userRef"] as? String,
            let roleValue = data["role"] as? Int,
            let role = Role(rawValue: roleValue),
            let firebaseRef = data["firebaseRef"] as? String
            //let hasOnlineVersion = data["hasOnlineVersion"] as? Bool
            else { return nil }
        self.timestamp = time.date
        self.email = email
        self.dataRef = dataRef
        self.userRef = userRef
        self.role = role
        self.firebaseRef = firebaseRef
        self.hasOnlineVersion = true
    }
    
    func forDatabase() -> [String: Any] {
        return [
            "dataRef": dataRef,
            "email": email.lowercased(),
            "firebaseRef": firebaseRef,
            "role": role.rawValue,
            "timestamp": timestamp.interval,
            "userRef" : userRef
        ]
    }
}

