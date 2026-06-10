import TinyConstraints
import UIKit

final class OrderPickerCategoryGridCell: UICollectionViewCell {
    static let reuseIdentifier = "OrderPickerCategoryGridCell"
    private enum Layout {
        static let imageAspectRatio: CGFloat = 2.0 / 3.0
    }

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageContainer, titleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 10
        return stack
    }()

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.14)
        view.layer.cornerRadius = 12
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
        imageView.image = AppImagePlaceholder.category()
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.body)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        contentView.backgroundColor = UIColor.TableView.cellBackground
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true

        imageContainer.addSubview(photoImageView)
        imageContainer.addSubview(placeholderImageView)
        contentView.addSubview(contentStackView)

        contentStackView.edgesToSuperview(insets: .uniform(12))
        imageContainer.heightToWidth(of: imageContainer, multiplier: Layout.imageAspectRatio)

        photoImageView.edgesToSuperview()

        placeholderImageView.centerInSuperview()
        placeholderImageView.size(CGSize(width: 26, height: 26))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.7 : 1
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.cancelImageLoad()
        photoImageView.image = nil
        placeholderImageView.isHidden = false
        titleLabel.text = nil
        accessibilityLabel = nil
    }

    func configure(title: String, imagePath: String?) {
        titleLabel.text = title
        accessibilityLabel = title
        accessibilityTraits = [.button]

        if let imagePath, !imagePath.isEmpty {
            imageContainer.backgroundColor = UIColor.TabBar.tint.alpha(0.14)
            photoImageView.setImage(
                pathOrURL: imagePath, placeholder: AppImagePlaceholder.category())
            placeholderImageView.isHidden = true
        } else {
            imageContainer.backgroundColor = UIColor.TabBar.tint.alpha(0.14)
            photoImageView.image = nil
            placeholderImageView.isHidden = false
        }
    }
}
