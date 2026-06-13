import UIKit

final class ProductPriceTableViewCell: ThumbnailListTableViewCell {
    func configure(productPrice: ProductsPriceModel) {
        configure(
            title: productPrice.name,
            secondaryText: productPrice.price.currency,
            imagePath: productPrice.imagePath,
            placeholder: AppImagePlaceholder.product()
        )
    }
}
