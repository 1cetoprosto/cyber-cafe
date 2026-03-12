import TinyConstraints
import UIKit

final class ProductGridCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductGridCell"

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

        let stack = UIStackView(arrangedSubviews: [titleLabel, priceLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 6
        contentView.addSubview(stack)
        stack.edgesToSuperview(insets: .uniform(12))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(title: String, price: String) {
        titleLabel.text = title
        priceLabel.text = price
        accessibilityLabel = "\(title), \(price)"
        accessibilityHint = R.string.global.add()
    }
}
