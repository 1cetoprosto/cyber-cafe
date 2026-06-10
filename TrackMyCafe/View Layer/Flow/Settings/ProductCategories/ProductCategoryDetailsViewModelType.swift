import Foundation

protocol ProductCategoryDetailsViewModelType: AnyObject {
    var title: String { get }
    var name: String { get }
    var imagePath: String? { get }

    func setName(_ name: String?)
    func setSelectedImageData(_ data: Data?)
    func markImageDeleted()
    func save() async throws
}

