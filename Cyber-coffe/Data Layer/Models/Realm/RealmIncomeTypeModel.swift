//
//  RealmIncomeTypeModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import RealmSwift

class RealmIncomeTypeModel: Object {
    @Persisted var id: String = ""
    @Persisted var name: String = ""
    
    convenience init(dataModel: IncomeTypeModel) {
        self.init()
        self.id = dataModel.id
        self.name = dataModel.name
    }
}
