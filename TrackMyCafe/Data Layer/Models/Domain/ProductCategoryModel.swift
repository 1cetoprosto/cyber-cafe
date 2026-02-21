import Foundation

struct ProductCategoryModel: Identifiable, Codable {
    let id: String
    var name: String
    var sortOrder: Int
    
    init(
        id: String = UUID().uuidString,
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }

    init(firebaseModel: FIRProductCategoryModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.sortOrder = firebaseModel.sortOrder
    }
}
