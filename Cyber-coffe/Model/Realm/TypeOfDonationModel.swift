//
//  TypeOfDonationModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import RealmSwift

class TypeOfDonationModel: Object {
    @Persisted var id: String = ""
    @Persisted var synchronized: Bool = false
    @Persisted var type: String = ""
    
    convenience init(documentId firId: String, firModel: FIRTypeOfDonationModel) {
        self.init()
        self.id = firId
        self.synchronized = true
        self.type = firModel.type
    }
}
