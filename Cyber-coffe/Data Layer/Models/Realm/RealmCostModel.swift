//
//  RealmCostModel.swift.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 29.12.2021.
//

import Foundation
import RealmSwift

class RealmCostModel: Object, Decodable {
    @Persisted var id: String = ""
    @Persisted var date: Date = Date()
    @Persisted var name: String = ""
    @Persisted var sum: Double = 0.0
    
    convenience init(dataModel: CostModel) {
        self.init()
        self.id = dataModel.id
        self.date = dataModel.date
        self.name = dataModel.name
        self.sum = dataModel.sum
    }
}
