//
//  FIRTypeOfDonationModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRIncomeTypeModel: Codable {
    @DocumentID var id: String?
    var name: String = ""
    
    init(dataModel: IncomeTypeModel) {
        self.id = dataModel.id
        self.name = dataModel.name
    }
}

//extension FIRIncomeTypeModel {
//    static var empty = FIRIncomeTypeModel(incomeTypeModel: RealmIncomeTypeModel())
//}
