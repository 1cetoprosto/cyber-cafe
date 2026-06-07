import TinyConstraints
import UIKit

final class OrderPickerProductTileCell: UICollectionViewCell {
    static let reuseIdentifier = "OrderPickerProductTileCell"

    var onMinusTapped: (() -> Void)?

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.TabBar.tint
        imageView.image = UIImage(systemName: "cup.and.saucer.fill")
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

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        contentView.backgroundColor = UIColor.TableView.cellBackground
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true

        contentView.addSubview(imageContainer)
        imageContainer.addSubview(imageView)
        imageContainer.addSubview(quantityLabel)
        contentView.addSubview(minusButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)

        imageContainer.topToSuperview(offset: 12)
        imageContainer.leftToSuperview(offset: 12)
        imageContainer.rightToSuperview(offset: -12)
        imageContainer.height(64)

        imageView.centerInSuperview()
        imageView.size(CGSize(width: 28, height: 28))

        quantityLabel.centerInSuperview()
        quantityLabel.leftToSuperview(offset: 8)
        quantityLabel.rightToSuperview(offset: -8)

        minusButton.size(CGSize(width: 32, height: 32))
        minusButton.centerYToSuperview()
        minusButton.rightToSuperview(offset: -10)

        titleLabel.topToBottom(of: imageContainer, offset: 10)
        titleLabel.leftToSuperview(offset: 12)
        titleLabel.rightToSuperview(offset: -12)

        priceLabel.topToBottom(of: titleLabel, offset: 4)
        priceLabel.leftToSuperview(offset: 12)
        priceLabel.rightToSuperview(offset: -12)
        priceLabel.bottomToSuperview(offset: -12, relation: .equalOrLess)

        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMinusTapped = nil
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

    func configure(title: String, price: String, quantity: Int) {
        titleLabel.text = title
        priceLabel.text = price

        let isActive = quantity > 0
        quantityLabel.isHidden = !isActive
        minusButton.isHidden = !isActive
        if isActive {
            quantityLabel.text = "\(quantity)"
            imageView.alpha = 0.18
            imageView.tintColor = UIColor.Main.text.withAlphaComponent(0.25)
        } else {
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
