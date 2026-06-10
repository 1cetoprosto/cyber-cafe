import Foundation

struct ProductCategoryModel: Identifiable, Codable {
    let id: String
    var name: String
    var sortOrder: Int
    var imagePath: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        sortOrder: Int = 0,
        imagePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.imagePath = imagePath
    }

    init(firebaseModel: FIRProductCategoryModel) {
        self.id = firebaseModel.id ?? ""
        self.name = firebaseModel.name
        self.sortOrder = firebaseModel.sortOrder
        self.imagePath = firebaseModel.imagePath
    }
}
