//
//  RealmTypeModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import RealmSwift
import Foundation

class RealmTypeModel: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String = ""
    @Persisted var isDefault: Bool = false
    
    convenience init(dataModel: TypeModel) {
        self.init()
        self.id = dataModel.id
        self.name = dataModel.name
        self.isDefault = dataModel.isDefault
    }
}
