import TinyConstraints
import UIKit

final class ProductGridCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductGridCell"
    private enum Layout {
        static let imageAspectRatio: CGFloat = 2.0 / 3.0
    }

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.TabBar.tint
        imageView.image = AppImagePlaceholder.product()
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.body)
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.footnote)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.TableView.cellBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        isAccessibilityElement = true

        imageContainer.addSubview(photoImageView)
        imageContainer.addSubview(placeholderImageView)

        photoImageView.edgesToSuperview()
        placeholderImageView.centerInSuperview()
        placeholderImageView.size(CGSize(width: 22, height: 22))

        let stack = UIStackView(arrangedSubviews: [imageContainer, titleLabel, priceLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 6
        contentView.addSubview(stack)
        stack.edgesToSuperview(insets: .uniform(12))

        imageContainer.heightToWidth(of: imageContainer, multiplier: Layout.imageAspectRatio)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.cancelImageLoad()
        photoImageView.image = nil
        placeholderImageView.isHidden = false
        titleLabel.text = nil
        priceLabel.text = nil
        accessibilityLabel = nil
    }

    func configure(title: String, price: String, imagePath: String?) {
        titleLabel.text = title
        priceLabel.text = price
        accessibilityLabel = "\(title), \(price)"
        accessibilityHint = R.string.global.add()

        if let imagePath, !imagePath.isEmpty {
            imageContainer.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
            photoImageView.setImage(
                pathOrURL: imagePath, placeholder: AppImagePlaceholder.product())
            placeholderImageView.isHidden = true
        } else {
            imageContainer.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
            photoImageView.image = nil
            placeholderImageView.isHidden = false
        }
    }
}
