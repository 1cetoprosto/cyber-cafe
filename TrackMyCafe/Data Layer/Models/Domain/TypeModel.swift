//
//  TypeModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct TypeModel {
    var id: String
    var name: String
    var isDefault: Bool = false
    
    init(id: String, name: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
    }
    
    init(realmModel: RealmTypeModel) {
        self.id = realmModel.id
        self.name = realmModel.name
        self.isDefault = realmModel.isDefault
    }
    
    init(firebaseModel: FIRTypeModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.isDefault = firebaseModel.isDefault
    }
}
