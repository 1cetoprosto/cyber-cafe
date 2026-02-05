//
//  Technician.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import Foundation

class Technician: BaseDatabaseModel, CustomStringConvertible {
    
    var ref: Refs {
        return Refs.technicians
    }
    
    var firebaseRef: String!
    var createdDate: Date
    var updatedDate: Date
    
    var firstName: String
    var lastName: String?
    var middleName: String?
    var email: String
    var phone: String?
    var address: String?
    var comment: String?
    var avatarUrl: String?
    var avatarThumbnailUrl: String?
    var enabled: Bool
    var role: Role
    var isAllowedCalculationsForAdministrator: Bool
    
    init() {
        self.firebaseRef = ""
        self.createdDate = Date()
        self.updatedDate = Date()
        
        self.firstName = ""
        self.lastName = nil
        self.middleName = nil
        self.email = ""
        self.phone = nil
        self.address = nil
        self.comment = nil
        self.avatarUrl = nil
        self.avatarThumbnailUrl = nil
        self.enabled = true
        self.role = .technician
        self.isAllowedCalculationsForAdministrator = false
    }
    
    init?(_ data: [String: Any]) {
        guard
            let firebaseRef = data[FirebaseFields.firebaseRef] as? String,
            let createdDate = data[FirebaseFields.createdDate] as? Double,
            let updateDate = data[FirebaseFields.updatedDate] as? Double,
            let firstName = data[FirebaseFields.firstName] as? String,
            let email = data[FirebaseFields.email] as? String
        else { return nil }
        self.firebaseRef = firebaseRef
        self.createdDate = Date(timeIntervalSince1970: createdDate)
        self.updatedDate = Date(timeIntervalSince1970: updateDate)
        
        self.firstName = firstName
        self.lastName = (data[FirebaseFields.lastName] as? String)?.nilIfEmpty
        self.middleName = (data[FirebaseFields.middleName] as? String)?.nilIfEmpty
        
        self.email = email
        self.phone = (data[FirebaseFields.phone] as? String)?.nilIfEmpty
        self.address = (data[FirebaseFields.address] as? String)?.nilIfEmpty
        self.comment = (data[FirebaseFields.comment] as? String)?.nilIfEmpty
        
        self.avatarUrl = (data[FirebaseFields.avatarUrl] as? String)?.nilIfEmpty
        self.avatarThumbnailUrl = (data[FirebaseFields.avatarThumbnailUrl] as? String)?.nilIfEmpty
        
        self.enabled = (data[FirebaseFields.enabled] as? Bool) ?? true
        
        let roleValue = data[FirebaseFields.role] as? Int
        self.role = Role(rawValue: roleValue ?? 2) ?? .technician
        self.isAllowedCalculationsForAdministrator =
        (data["isAllowedCalculationsForAdministrator"] as? Bool) ?? false
    }
    
    func forDatabase() -> [String: Any] {
        return [
            FirebaseFields.firebaseRef: firebaseRef!,
            FirebaseFields.createdDate: createdDate.interval,
            FirebaseFields.updatedDate: Date().interval,
            
            FirebaseFields.firstName: firstName,
            FirebaseFields.lastName: lastName.emptyIfNil,
            FirebaseFields.middleName: middleName.emptyIfNil,
            
            FirebaseFields.avatarUrl: avatarUrl.emptyIfNil,
            FirebaseFields.avatarThumbnailUrl: avatarThumbnailUrl.emptyIfNil,
            
            FirebaseFields.email: email.lowercased(),
            FirebaseFields.phone: phone.emptyIfNil,
            FirebaseFields.address: address.emptyIfNil,
            FirebaseFields.comment: comment.emptyIfNil,
            
            FirebaseFields.enabled: enabled,
            FirebaseFields.role: role.rawValue,
            "isAllowedCalculationsForAdministrator": isAllowedCalculationsForAdministrator,
        ]
    }
    
    func copy() -> Technician {
        let newObject = Technician()
        newObject.firebaseRef = self.firebaseRef
        newObject.createdDate = self.createdDate
        newObject.updatedDate = self.updatedDate
        
        newObject.firstName = self.firstName
        newObject.lastName = self.lastName
        newObject.middleName = self.middleName
        
        newObject.email = self.email
        newObject.phone = self.phone
        newObject.address = self.address
        newObject.comment = self.comment
        
        newObject.avatarUrl = self.avatarUrl
        newObject.avatarThumbnailUrl = self.avatarThumbnailUrl
        newObject.enabled = self.enabled
        newObject.role = self.role
        newObject.isAllowedCalculationsForAdministrator = self.isAllowedCalculationsForAdministrator
        return newObject
    }
}

extension Technician {
    
    func fullNameReversed() -> String {
        return [lastName, firstName, middleName].compactMap { $0 }.filter { !$0.isEmpty }.joined(
            separator: " ")
    }
    
    func fullName() -> String {
        return [lastName, firstName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    func shortName() -> String {
        if lastName?.nilIfEmpty == nil {
            return firstName
        }
        return
        ([lastName].compactMap { $0 }
         + [firstName.first, middleName?.first].compactMap { $0 }.map { "\($0)." }).joined(
            separator: " ")
    }
}

extension Technician: PersonListModelProtocol {
    
    var name: String {
        return [lastName, firstName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    var phoneValue: String? {
        return phone
    }
    
    var profileImagePath: String? {
        return avatarThumbnailUrl ?? avatarUrl
    }
}

//extension Technician: SelectItemProtocol {
//
//    var title: String {
//        return fullName()
//    }
//}
