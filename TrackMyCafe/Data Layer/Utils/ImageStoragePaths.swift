import Foundation

enum ImageStoragePaths {
    static func productImagePath(productId: String) -> String {
        "productImages/products/\(productId).jpg"
    }

    static func productCategoryImagePath(categoryId: String) -> String {
        "productImages/categories/\(categoryId).jpg"
    }
}

