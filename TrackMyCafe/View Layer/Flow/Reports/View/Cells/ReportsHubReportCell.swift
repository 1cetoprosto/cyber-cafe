import TinyConstraints
import UIKit

final class ReportsHubReportCell: UITableViewCell {

    static let identifier = "ReportsHubReportCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.current.cellBackground
        view.layer.cornerRadius = UIConstants.mediumCornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.06
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = UIConstants.mediumCornerRadius
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppLabel(style: .title3DemiBold)
        label.apply(.title3DemiBold)
        label.textColor = Theme.current.primaryText
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = Theme.current.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: SystemImages.chevronRight)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Theme.current.secondaryText
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.shadowPath =
            UIBezierPath(
                roundedRect: containerView.bounds, cornerRadius: UIConstants.mediumCornerRadius
            ).cgPath
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: animated ? 0.15 : 0) {
            self.containerView.alpha = highlighted ? 0.75 : 1
            self.containerView.transform =
                highlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
        }
    }

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(chevronImageView)

        containerView.edgesToSuperview(
            insets: UIEdgeInsets(
                top: UIConstants.smallSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.smallSpacing,
                right: UIConstants.standardPadding)
        )

        iconContainerView.leftToSuperview(offset: UIConstants.mediumSpacing)
        iconContainerView.centerYToSuperview()
        iconContainerView.size(CGSize(width: 44, height: 44))

        iconImageView.centerInSuperview()
        iconImageView.size(
            CGSize(width: UIConstants.largeIconSize, height: UIConstants.largeIconSize))

        chevronImageView.rightToSuperview(offset: -UIConstants.mediumSpacing)
        chevronImageView.centerYToSuperview()
        chevronImageView.size(CGSize(width: 18, height: 18))

        titleLabel.leftToRight(of: iconContainerView, offset: UIConstants.mediumSpacing)
        titleLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        titleLabel.rightToLeft(of: chevronImageView, offset: -UIConstants.smallSpacing)

        subtitleLabel.left(to: titleLabel)
        subtitleLabel.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
        subtitleLabel.right(to: titleLabel)
        subtitleLabel.bottomToSuperview(offset: -UIConstants.mediumSpacing)
    }

    func configure(kind: ReportListKind, title: String, subtitle: String, symbol: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconImageView.image = UIImage(systemName: symbol)

        let accent: UIColor
        switch kind {
        case .pl: accent = .systemGreen
        case .abc: accent = Theme.current.tabBarTint
        case .trends: accent = .systemOrange
        }
        iconContainerView.backgroundColor = accent.withAlphaComponent(0.15)
        iconImageView.tintColor = accent
    }
}
