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
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    init(realmModel: RealmTypeModel) {
        self.id = realmModel.id
        self.name = realmModel.name
    }
    
    init(firebaseModel: FIRTypeModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
    }
}

