import UIKit

final class ProductCategoryTableViewCell: ThumbnailListTableViewCell {
    static let reuseIdentifier = "ProductCategoryTableViewCell"

    func configure(category: ProductCategoryModel) {
        configure(
            title: category.name,
            secondaryText: nil,
            imagePath: category.imagePath,
            placeholder: AppImagePlaceholder.category()
        )
    }
}
