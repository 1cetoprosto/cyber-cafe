import Foundation

enum ImageStoragePaths {
    /// Cafe id for tenant-scoped Storage paths (`masterUserRef`, else session user id).
    private static var cafeId: String? {
        if let master = UserSession.current.masterUserRef, !master.isEmpty {
            return master
        }
        if let userId = UserSession.current.userId, !userId.isEmpty {
            return userId
        }
        return nil
    }

    /// Legacy flat path — existing product images already live here.
    static func productImagePath(productId: String) -> String {
        "productImages/products/\(productId).jpg"
    }

    /// Legacy flat path — existing category images already live here.
    static func productCategoryImagePath(categoryId: String) -> String {
        "productImages/categories/\(categoryId).jpg"
    }

    /// Prefer `Avatars/{cafeId}/{file}` for new uploads (Storage rules + membership).
    static func avatarPath(fileName: String) -> String {
        if let cafeId {
            return "\(Refs.avatars.rawValue)/\(cafeId)/\(fileName)"
        }
        return "\(Refs.avatars.rawValue)/\(fileName)"
    }
}
