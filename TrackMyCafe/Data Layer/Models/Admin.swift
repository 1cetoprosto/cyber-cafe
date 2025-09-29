//
//  Admin.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import Foundation
import FirebaseFirestore

class Admin: CustomStringConvertible {

    var firebaseRef: String!
    var firstName: String
    var lastName: String?
    var middleName: String?
    var email: String
    var phone: String?
    var address: String?
    var comment: String?
    var avatarUrl: String?
    var avatarThumbnailUrl: String?
    
    var fullName: String {
        return [lastName, firstName, middleName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    init() {
        self.firebaseRef = ""
        
        self.firstName = ""
        self.lastName = nil
        self.middleName = nil
        self.email = ""
        self.phone = nil
        self.address = nil
        self.comment = nil
        self.avatarUrl = nil
        self.avatarThumbnailUrl = nil
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.firebaseRef = document.documentID
        self.firstName = data[FirebaseFields.firstName] as? String ?? ""
        self.lastName = data[FirebaseFields.lastName] as? String
        self.middleName = data[FirebaseFields.middleName] as? String
        self.email = data[FirebaseFields.email] as? String ?? ""
        self.phone = data[FirebaseFields.phone] as? String
        self.address = data[FirebaseFields.address] as? String
        self.comment = data[FirebaseFields.comment] as? String
        self.avatarUrl = data[FirebaseFields.avatarUrl] as? String
        self.avatarThumbnailUrl = data[FirebaseFields.avatarThumbnailUrl] as? String
    }
    
    func forDatabase() -> [String: Any] {
        return [
            FirebaseFields.updatedDate: Date().timeIntervalSince1970,
            
            FirebaseFields.firstName: firstName,
            FirebaseFields.lastName: lastName ?? "",
            FirebaseFields.middleName: middleName ?? "",
            
            FirebaseFields.avatarUrl: avatarUrl ?? "",
            FirebaseFields.avatarThumbnailUrl: avatarThumbnailUrl ?? "",
            
            FirebaseFields.email: email.lowercased(),
            FirebaseFields.phone: phone ?? "",
            FirebaseFields.address: address ?? "",
            FirebaseFields.comment: comment ?? ""
        ]
    }
    
    func copy() -> Admin {
        let newObject = Admin()
        newObject.firebaseRef = self.firebaseRef
        
        newObject.firstName = self.firstName
        newObject.lastName = self.lastName
        newObject.middleName = self.middleName
        
        newObject.email = self.email
        newObject.phone = self.phone
        newObject.address = self.address
        newObject.comment = self.comment
        
        newObject.avatarUrl = self.avatarUrl
        newObject.avatarThumbnailUrl = self.avatarThumbnailUrl
        return newObject
    }
}

extension Admin: PersonListModelProtocol {
    
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

//extension Admin: SelectItemProtocol {
//    
//    var title: String {
//        return fullName
//    }
//}

