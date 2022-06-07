//
//  FIRTypeOfDonationModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRTypeOfDonationModel: Codable {
    @DocumentID var id: String?
var type: String = ""
    
    //    enum CodingCase: String, CodingKey {
    //        case id
    //        case saleDate
    //        case saleGood
    //        case saleQty
    //        case salePrice
    //        case saleSum
    //    }
    //
    init(typeOfDonationModel: TypeOfDonationModel) {
        self.id = typeOfDonationModel.typeOfDonationId
        self.type = typeOfDonationModel.type
    }
    
    init(id: String?,
         type: String) {
        self.id = id
        self.type = type
    }
    
}

extension FIRTypeOfDonationModel {
    static var empty = FIRTypeOfDonationModel(typeOfDonationModel: TypeOfDonationModel())
}
