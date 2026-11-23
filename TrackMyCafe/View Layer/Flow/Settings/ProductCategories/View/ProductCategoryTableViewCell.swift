import UIKit

final class ProductCategoryTableViewCell: BaseListTableViewCell {
    static let reuseIdentifier = "ProductCategoryTableViewCell"

    /// Enough pixels for a ~44pt list thumbnail on 3x displays.
    private static let listThumbnailMaxPixels = 132

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        selectionStyle = .default
        accessoryType = .disclosureIndicator
        textLabel?.applyDynamic(Typography.body)
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.cornerRadius = UIConstants.smallCornerRadius
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.cancelImageLoad()
        imageView?.image = nil
        textLabel?.text = nil
    }

    func configure(category: ProductCategoryModel) {
        textLabel?.text = category.name
        let placeholder = AppImagePlaceholder.category()
        imageView?.setImage(
            pathOrURL: category.imagePath,
            placeholder: placeholder,
            maxPixelSize: Self.listThumbnailMaxPixels
        )
    }
}
