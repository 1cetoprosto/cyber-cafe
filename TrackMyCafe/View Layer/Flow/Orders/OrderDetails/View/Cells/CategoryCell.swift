import TinyConstraints
import UIKit

final class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.body)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 0
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowRadius = 8
        contentView.layer.shadowOpacity = 0

        isAccessibilityElement = true
        contentView.addSubview(titleLabel)
        titleLabel.edgesToSuperview(insets: .horizontal(12))
        titleLabel.centerYToSuperview()

        updateAppearance(isSelected: false)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.7 : 1
        }
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        accessibilityLabel = title
        updateAppearance(isSelected: isSelected)
    }

    private func updateAppearance(isSelected: Bool) {
        contentView.backgroundColor = isSelected ? UIColor.TabBar.tint.alpha(0.18) : UIColor.TableView.cellBackground
        titleLabel.applyDynamic(isSelected ? Typography.bodyBold : Typography.body)
        contentView.layer.shadowOpacity = isSelected ? 0.08 : 0
        accessibilityTraits = isSelected ? [.button, .selected] : [.button]
    }
}
