import TinyConstraints
import UIKit

class ThumbnailListTableViewCell: BaseListTableViewCell {
    private enum Layout {
        static let thumbnailSize = CGSize(width: 30, height: 30)
        static let placeholderSize = CGSize(width: 18, height: 18)
        static let horizontalInset: CGFloat = 15
        static let interItemSpacing: CGFloat = 10
        static let trailingAccessoryInset: CGFloat = 10
        static let separatorInsetLeft: CGFloat = 55
        static let separatorInsetRight: CGFloat = 15
    }

    private let thumbnailContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
        view.layer.cornerRadius = 8
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
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        return label
    }()

    private let secondaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .right
        label.textColor = UIColor.TableView.cellLabel
        label.applyDynamic(Typography.body)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let spacerView = UIView()
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, spacerView, secondaryLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Layout.interItemSpacing
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero
        separatorInset = UIEdgeInsets(
            top: 0,
            left: Layout.separatorInsetLeft,
            bottom: 0,
            right: Layout.separatorInsetRight
        )

        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.cancelImageLoad()
        photoImageView.image = nil
        placeholderImageView.isHidden = false
        placeholderImageView.image = nil
        titleLabel.text = nil
        secondaryLabel.text = nil
        secondaryLabel.isHidden = false
        accessibilityLabel = nil
    }

    func configure(
        title: String,
        secondaryText: String?,
        imagePath: String?,
        placeholder: UIImage?
    ) {
        titleLabel.text = title
        secondaryLabel.text = secondaryText
        secondaryLabel.isHidden = secondaryText == nil
        placeholderImageView.image = placeholder

        if let imagePath, !imagePath.isEmpty {
            placeholderImageView.isHidden = true
            photoImageView.setImage(pathOrURL: imagePath, placeholder: nil)
        } else {
            photoImageView.cancelImageLoad()
            photoImageView.image = nil
            placeholderImageView.isHidden = false
        }

        if let secondaryText, !secondaryText.isEmpty {
            accessibilityLabel = "\(title), \(secondaryText)"
        } else {
            accessibilityLabel = title
        }
    }

    private func setupViews() {
        contentView.addSubview(thumbnailContainerView)
        thumbnailContainerView.addSubview(photoImageView)
        thumbnailContainerView.addSubview(placeholderImageView)
        contentView.addSubview(textStackView)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        secondaryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        secondaryLabel.setContentHuggingPriority(.required, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func setupLayout() {
        thumbnailContainerView.leftToSuperview(offset: Layout.horizontalInset)
        thumbnailContainerView.centerYToSuperview()
        thumbnailContainerView.size(Layout.thumbnailSize)

        photoImageView.edgesToSuperview()

        placeholderImageView.centerInSuperview()
        placeholderImageView.size(Layout.placeholderSize)

        textStackView.leftToRight(of: thumbnailContainerView, offset: Layout.interItemSpacing)
        textStackView.centerYToSuperview()
        textStackView.rightToSuperview(offset: -Layout.trailingAccessoryInset)
    }
}
