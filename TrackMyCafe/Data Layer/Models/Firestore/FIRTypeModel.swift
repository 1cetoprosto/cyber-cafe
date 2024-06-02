//
//  FIRTypeModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRTypeModel: Codable {
    @DocumentID var id: String?
    var name: String = ""
    
    init(dataModel: TypeModel) {
        self.id = dataModel.id
        self.name = dataModel.name
    }
}

//extension FIRTypeModel {
//    static var empty = FIRTypeModel(typeModel: RealmTypeModel())
//}
