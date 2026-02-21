import FirebaseFirestoreSwift
import Foundation

struct FIRProductCategoryModel: Codable {
    @DocumentID var id: String?
    var name: String = ""
    var sortOrder: Int = 0
    
    init(dataModel: ProductCategoryModel) {
        self.id = dataModel.id
        self.name = dataModel.name
        self.sortOrder = dataModel.sortOrder
    }
}

