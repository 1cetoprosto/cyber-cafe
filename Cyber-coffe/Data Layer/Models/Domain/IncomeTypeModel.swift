//
//  IncomeTypeModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 11.05.2024.
//

import Foundation

struct IncomeTypeModel {
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    init(realmModel: RealmIncomeTypeModel) {
        self.id = realmModel.id
        self.name = realmModel.name
    }
    
    init(firebaseModel: FIRIncomeTypeModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
    }
}

