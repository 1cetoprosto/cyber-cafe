//
//  InventoryAdjustmentCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import TinyConstraints
import UIKit

final class InventoryAdjustmentCell: BaseListTableViewCell {

    // MARK: - Views

    private let titleLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 0
        return label
    }()

    private let deltaLabel: AppLabel = {
        let label = AppLabel(style: .bodyValue)
        label.textAlignment = .right
        return label
    }()

    private let dateLabel: AppLabel = {
        let label = AppLabel(style: .footnoteValue)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Setup

    private func setupUI() {
        accessoryType = .disclosureIndicator

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        leftStack.axis = .vertical
        leftStack.spacing = UIConstants.smallSpacing

        let rightStack = UIStackView(arrangedSubviews: [deltaLabel, dateLabel])
        rightStack.axis = .vertical
        rightStack.spacing = UIConstants.smallSpacing
        rightStack.alignment = .trailing

        rightStack.setContentHuggingPriority(.required, for: .horizontal)
        rightStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leftStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rootStack = UIStackView(arrangedSubviews: [leftStack, rightStack])
        rootStack.axis = .horizontal
        rootStack.alignment = .top
        rootStack.distribution = .fill
        rootStack.spacing = UIConstants.standardSpacing

        contentView.addSubview(rootStack)
        rootStack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardSpacing,
                right: UIConstants.standardPadding
            )
        )
    }

    // MARK: - Configuration

    func configure(with viewModel: InventoryAdjustmentListItemViewModel) {
        titleLabel.text = viewModel.ingredientName

        var subtitle = viewModel.sourceText
        if let reason = viewModel.reasonText, !reason.isEmpty {
            subtitle += " • \(reason)"
        }
        subtitleLabel.text = subtitle

        deltaLabel.text = viewModel.deltaText
        deltaLabel.textColor = viewModel.deltaSign == .plus
            ? UIColor.Main.systemGreenEquivalent ?? .systemGreen
            : UIColor.Main.systemRedEquivalent ?? .systemRed

        dateLabel.text = viewModel.dateText
    }
}

private extension UIColor.Main {
    static let systemGreenEquivalent: UIColor? = nil
    static let systemRedEquivalent: UIColor? = nil
}
