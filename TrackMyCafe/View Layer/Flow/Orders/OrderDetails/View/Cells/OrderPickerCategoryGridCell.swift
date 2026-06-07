import TinyConstraints
import UIKit

final class OrderPickerCategoryGridCell: UICollectionViewCell {
    static let reuseIdentifier = "OrderPickerCategoryGridCell"

    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.14)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.TabBar.tint
        imageView.image = UIImage(systemName: "square.grid.2x2")
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

        contentView.addSubview(iconView)
        iconView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconView.topToSuperview(offset: 12)
        iconView.centerXToSuperview()
        iconView.size(CGSize(width: 56, height: 56))

        iconImageView.centerInSuperview()
        iconImageView.size(CGSize(width: 26, height: 26))

        titleLabel.topToBottom(of: iconView, offset: 10)
        titleLabel.leftToSuperview(offset: 10)
        titleLabel.rightToSuperview(offset: -10)
        titleLabel.bottomToSuperview(offset: -10, relation: .equalOrLess)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.7 : 1
        }
    }

    func configure(title: String) {
        titleLabel.text = title
        accessibilityLabel = title
        accessibilityTraits = [.button]
    }
}
