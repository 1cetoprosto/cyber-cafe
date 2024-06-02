//
//  FIRCostModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 06.06.2022.
//

import Foundation
import FirebaseFirestoreSwift

struct FIRCostModel: Codable {
    @DocumentID var id: String?
    var date: Date = Date()
    var name: String = ""
    var sum: Double = 0.0
    
    init(dataModel: CostModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.name = dataModel.name
        self.sum = dataModel.sum
    }
}

//extension FIRCostModel {
//    static var empty = FIRCostModel(costModel: RealmCostModel())
//}
