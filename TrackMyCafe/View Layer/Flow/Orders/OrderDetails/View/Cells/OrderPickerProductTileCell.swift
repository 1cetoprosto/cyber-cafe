import TinyConstraints
import UIKit

final class OrderPickerProductTileCell: UICollectionViewCell {
    static let reuseIdentifier = "OrderPickerProductTileCell"
    private enum Layout {
        static let imageAspectRatio: CGFloat = 2.0 / 3.0
    }

    var onMinusTapped: (() -> Void)?

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
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

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.TabBar.tint
        imageView.image = AppImagePlaceholder.product()
        return imageView
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.Main.text
        let baseSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
        let baseFont = AvenirNext.font(size: baseSize, weight: .demiBold)
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: baseFont)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.isHidden = true
        return label
    }()

    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.systemRed
        button.setImage(UIImage(systemName: "minus"), for: .normal)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isHidden = true
        button.accessibilityLabel = "-"
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.bodyBold)
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.footnote)
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, priceLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 4
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        contentView.backgroundColor = UIColor.TableView.cellBackground
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true

        contentView.addSubview(imageContainer)
        imageContainer.addSubview(photoImageView)
        imageContainer.addSubview(imageView)
        imageContainer.addSubview(quantityLabel)
        contentView.addSubview(minusButton)
        contentView.addSubview(textStackView)

        imageContainer.topToSuperview(offset: 12)
        imageContainer.leftToSuperview(offset: 12)
        imageContainer.rightToSuperview(offset: -12)
        imageContainer.heightToWidth(of: imageContainer, multiplier: Layout.imageAspectRatio)

        photoImageView.edgesToSuperview()

        imageView.centerInSuperview()
        imageView.size(CGSize(width: 28, height: 28))

        quantityLabel.centerInSuperview()
        quantityLabel.leftToSuperview(offset: 8)
        quantityLabel.rightToSuperview(offset: -8)

        minusButton.size(CGSize(width: 32, height: 32))
        minusButton.centerYToSuperview()
        minusButton.rightToSuperview(offset: -10)

        textStackView.topToBottom(of: imageContainer, offset: 10)
        textStackView.leftToSuperview(offset: 12)
        textStackView.rightToSuperview(offset: -(12 + 32 + 10))
        textStackView.bottomToSuperview(offset: -12)

        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMinusTapped = nil
        photoImageView.cancelImageLoad()
        photoImageView.image = nil
        photoImageView.alpha = 1
        quantityLabel.isHidden = true
        minusButton.isHidden = true
        quantityLabel.text = nil
        titleLabel.text = nil
        priceLabel.text = nil
        accessibilityLabel = nil
        imageView.alpha = 1
        imageView.tintColor = UIColor.TabBar.tint
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.7 : 1
        }
    }

    func configure(title: String, price: String, quantity: Int, imagePath: String?) {
        titleLabel.text = title
        priceLabel.text = price

        if let imagePath, !imagePath.isEmpty {
            imageContainer.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
            photoImageView.setImage(
                pathOrURL: imagePath, placeholder: AppImagePlaceholder.product())
            imageView.isHidden = true
        } else {
            imageContainer.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
            photoImageView.image = nil
            imageView.isHidden = false
        }

        let isActive = quantity > 0
        quantityLabel.isHidden = !isActive
        minusButton.isHidden = !isActive
        if isActive {
            quantityLabel.text = "\(quantity)"
            if imageView.isHidden {
                photoImageView.alpha = 0.35
            } else {
                imageView.alpha = 0.18
                imageView.tintColor = UIColor.Main.text.withAlphaComponent(0.25)
            }
        } else {
            photoImageView.alpha = 1
            imageView.alpha = 1
            imageView.tintColor = UIColor.TabBar.tint
        }

        if isActive {
            accessibilityLabel = "\(title), \(price), \(quantity)"
        } else {
            accessibilityLabel = "\(title), \(price)"
        }
        accessibilityHint = R.string.global.add()
    }

    @objc private func minusTapped() {
        onMinusTapped?()
    }
}
