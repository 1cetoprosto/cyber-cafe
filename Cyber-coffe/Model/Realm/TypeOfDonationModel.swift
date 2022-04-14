//
//  TypeOfDonationModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import RealmSwift

class TypeOfDonationModel: Object {
    @Persisted var type: String = ""
}
