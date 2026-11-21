//
//  OnboardingCell.swift
//  TrackMyCafe
//

import TinyConstraints
import UIKit

final class OnboardingCell: UICollectionViewCell {

    static let reuseId = "OnboardingCell"

    // MARK: - UI Elements

    private let iconBadge: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 28
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: AppLabel = {
        let label = AppLabel(style: .largeTitleBold)
        label.apply(.largeTitleBold)
        label.textColor = Theme.current.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.apply(.bodyMultiline)
        label.textColor = Theme.current.secondaryText
        label.textAlignment = .center
        return label
    }()

    private let demoCard: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.current.cellBackground
        view.applyCafeSoftCardStyle()
        return view
    }()

    private let comparisonLabel: AppLabel = {
        let label = AppLabel(style: .bodyDemiBold)
        label.apply(.bodyDemiBold)
        label.textColor = Theme.current.secondaryText
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let sectionCaptionLabel: AppLabel = {
        let label = AppLabel(style: .kpiTitle)
        label.apply(.kpiTitle)
        label.textColor = UIColor.Semantic.kpiLabel
        label.textAlignment = .left
        return label
    }()

    private let heroCaptionLabel: AppLabel = {
        let label = AppLabel(style: .kpiTitle)
        label.apply(.kpiTitle)
        label.textColor = UIColor.Semantic.kpiLabel
        label.textAlignment = .center
        return label
    }()

    private let heroValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 44, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.current.primaryText
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.45
        label.numberOfLines = 1
        return label
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.Semantic.cardStroke
        return view
    }()

    private let linesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        return stack
    }()

    private let demoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        return stack
    }()

    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clearLines()
        heroValueLabel.attributedText = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        demoCard.updateCafeSoftCardShadowPath()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(contentStack)

        iconBadge.addSubview(iconView)
        iconView.size(CGSize(width: 28, height: 28))
        iconView.centerInSuperview()
        iconBadge.size(CGSize(width: 56, height: 56))

        headerStack.addArrangedSubview(iconBadge)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(descriptionLabel)

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(demoCard)
        contentStack.setCustomSpacing(24, after: headerStack)

        demoCard.addSubview(demoStack)
        demoStack.edgesToSuperview(insets: .uniform(20))

        contentStack.topToSuperview(offset: 20, usingSafeArea: true)
        contentStack.centerXToSuperview()
        contentStack.widthToSuperview(multiplier: 0.9)
        contentStack.bottomToSuperview(offset: -8, relation: .equalOrLess, usingSafeArea: true)

        titleLabel.widthToSuperview()
        descriptionLabel.widthToSuperview()
        demoCard.widthToSuperview()
        headerStack.widthToSuperview()
    }

    // MARK: - Configure

    func configure(with slide: OnboardingSlide) {
        titleLabel.text = slide.title
        descriptionLabel.text = slide.description

        heroCaptionLabel.text = slide.heroCaption
        heroCaptionLabel.isHidden = slide.heroCaption == nil

        applyHeroValue(slide.heroValue, style: slide.heroStyle)
        applyChrome(for: slide.kind)
        rebuildLines(for: slide)

        comparisonLabel.text = slide.comparisonText
        comparisonLabel.isHidden = slide.comparisonText == nil

        sectionCaptionLabel.text = R.string.global.onboardingDemoOneSale()
        sectionCaptionLabel.isHidden = slide.kind != .receiptToShift

        demoStack.arrangedSubviews.forEach { view in
            demoStack.removeArrangedSubview(view)
        }

        switch slide.kind {
        case .receiptToShift:
            demoStack.addArrangedSubview(sectionCaptionLabel)
            demoStack.addArrangedSubview(linesStack)
            demoStack.addArrangedSubview(divider)
            demoStack.addArrangedSubview(heroCaptionLabel)
            demoStack.addArrangedSubview(heroValueLabel)
            demoStack.setCustomSpacing(8, after: sectionCaptionLabel)
            demoStack.setCustomSpacing(16, after: linesStack)
            demoStack.setCustomSpacing(14, after: divider)
            demoStack.setCustomSpacing(6, after: heroCaptionLabel)
        case .expenses:
            demoStack.addArrangedSubview(heroCaptionLabel)
            demoStack.addArrangedSubview(heroValueLabel)
            demoStack.addArrangedSubview(divider)
            demoStack.addArrangedSubview(linesStack)
            demoStack.setCustomSpacing(6, after: heroCaptionLabel)
            demoStack.setCustomSpacing(16, after: heroValueLabel)
            demoStack.setCustomSpacing(16, after: divider)
        case .whatsLeft:
            demoStack.addArrangedSubview(comparisonLabel)
            demoStack.addArrangedSubview(heroCaptionLabel)
            demoStack.addArrangedSubview(heroValueLabel)
            demoStack.addArrangedSubview(divider)
            demoStack.addArrangedSubview(linesStack)
            demoStack.setCustomSpacing(10, after: comparisonLabel)
            demoStack.setCustomSpacing(6, after: heroCaptionLabel)
            demoStack.setCustomSpacing(16, after: heroValueLabel)
            demoStack.setCustomSpacing(16, after: divider)
        }

        divider.height(1 / UIScreen.main.scale)
        setNeedsLayout()
    }

    private func applyHeroValue(_ value: String?, style: OnboardingHeroStyle) {
        heroValueLabel.isHidden = value == nil
        guard let value else {
            heroValueLabel.text = nil
            heroValueLabel.attributedText = nil
            return
        }

        switch style {
        case .sales:
            heroValueLabel.attributedText = nil
            heroValueLabel.text = value
            heroValueLabel.textColor = Theme.current.primaryText
            heroValueLabel.alpha = 1
        case .mutedSales:
            let attributed = NSAttributedString(
                string: value,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 44, weight: .bold),
                    .foregroundColor: Theme.current.secondaryText,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: Theme.current.secondaryText
                ]
            )
            heroValueLabel.attributedText = attributed
            heroValueLabel.alpha = 0.85
        case .leftover:
            heroValueLabel.attributedText = nil
            heroValueLabel.text = value
            heroValueLabel.textColor = UIColor.Semantic.positive
            heroValueLabel.alpha = 1
        }
    }

    private func applyChrome(for kind: OnboardingSlideKind) {
        switch kind {
        case .receiptToShift:
            iconBadge.backgroundColor = UIColor.Semantic.positiveFill
            iconView.tintColor = UIColor.Semantic.positive
            iconView.image = UIImage(systemName: "cart.fill")
        case .expenses:
            iconBadge.backgroundColor = UIColor.Semantic.costFill
            iconView.tintColor = UIColor.Semantic.cost
            iconView.image = UIImage(systemName: "arrow.down.right.circle.fill")
        case .whatsLeft:
            iconBadge.backgroundColor = UIColor.Semantic.positiveFill
            iconView.tintColor = UIColor.Semantic.positive
            iconView.image = UIImage(systemName: "chart.bar.fill")
        }
    }

    private func rebuildLines(for slide: OnboardingSlide) {
        clearLines()
        for line in slide.lines {
            switch slide.kind {
            case .receiptToShift:
                linesStack.addArrangedSubview(makeReceiptRow(line))
            case .expenses:
                linesStack.addArrangedSubview(makeExpenseRow(line))
            case .whatsLeft:
                linesStack.addArrangedSubview(makeSummaryRow(line))
                if line.showsDividerAfter {
                    let lineDivider = UIView()
                    lineDivider.backgroundColor = UIColor.Semantic.cardStroke
                    lineDivider.height(1 / UIScreen.main.scale)
                    linesStack.addArrangedSubview(lineDivider)
                }
            }
        }
    }

    private func clearLines() {
        linesStack.arrangedSubviews.forEach { view in
            linesStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    // MARK: - Rows

    private func makeReceiptRow(_ line: OnboardingDemoLine) -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.current.primaryBackground
        container.layer.cornerRadius = 14

        let title = AppLabel(style: .bodyMedium)
        title.apply(.bodyMedium)
        title.text = line.title
        title.textColor = Theme.current.primaryText

        let value = AppLabel(style: .bodyDemiBold)
        value.apply(.bodyDemiBold)
        value.text = line.value
        value.textAlignment = .right
        value.textColor = Theme.current.primaryText
        value.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [title, value])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center

        container.addSubview(row)
        row.edgesToSuperview(insets: .uniform(14))
        return container
    }

    private func makeExpenseRow(_ line: OnboardingDemoLine) -> UIView {
        let badge = UIView()
        badge.backgroundColor = UIColor.Semantic.costFill
        badge.layer.cornerRadius = 14
        badge.size(CGSize(width: 28, height: 28))

        let icon = UIImageView(image: UIImage(systemName: "minus"))
        icon.tintColor = UIColor.Semantic.cost
        icon.contentMode = .scaleAspectFit
        badge.addSubview(icon)
        icon.size(CGSize(width: 12, height: 12))
        icon.centerInSuperview()

        let title = AppLabel(style: .body)
        title.apply(.body)
        title.text = line.title
        title.textColor = Theme.current.secondaryText

        let value = AppLabel(style: .bodyDemiBold)
        value.apply(.bodyDemiBold)
        value.text = line.value
        value.textAlignment = .right
        value.textColor = UIColor.Semantic.cost
        value.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [title, value])
        textStack.axis = .horizontal
        textStack.spacing = 8
        textStack.alignment = .firstBaseline

        let row = UIStackView(arrangedSubviews: [badge, textStack])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        return row
    }

    private func makeSummaryRow(_ line: OnboardingDemoLine) -> UIView {
        let title = AppLabel(style: .body)
        title.apply(.body)
        title.text = line.title
        title.textColor = Theme.current.secondaryText

        let value = AppLabel(style: .bodyDemiBold)
        value.apply(.bodyDemiBold)
        value.text = line.value
        value.textAlignment = .right
        value.setContentHuggingPriority(.required, for: .horizontal)

        switch line.tone {
        case .neutral:
            value.textColor = Theme.current.primaryText
        case .positive:
            value.textColor = UIColor.Semantic.positive
        case .negative:
            value.textColor = UIColor.Semantic.cost
        case .emphasized:
            value.textColor = UIColor.Semantic.positive
        }

        let row = UIStackView(arrangedSubviews: [title, value])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .firstBaseline
        return row
    }
}
