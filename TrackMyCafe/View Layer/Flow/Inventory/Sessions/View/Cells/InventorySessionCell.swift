//
//  InventorySessionCell.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 26.08.2026.
//

import TinyConstraints
import UIKit

final class InventorySessionCell: BaseListTableViewCell {

    // MARK: - Views

    private let dateLabel: AppLabel = {
        let label = AppLabel(style: .headline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 1
        return label
    }()

    private let summaryLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 1
        return label
    }()

    private let noteLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Setup

    private func setupUI() {
        accessoryType = .disclosureIndicator

        let headerStack = UIStackView(arrangedSubviews: [dateLabel, summaryLabel])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        headerStack.alignment = .lastBaseline
        headerStack.spacing = UIConstants.standardSpacing

        summaryLabel.setContentHuggingPriority(.required, for: .horizontal)
        summaryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let root = UIStackView(arrangedSubviews: [headerStack, noteLabel])
        root.axis = .vertical
        root.spacing = UIConstants.smallSpacing

        contentView.addSubview(root)
        root.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardSpacing,
                right: UIConstants.standardPadding
            )
        )
    }

    // MARK: - Configuration

    func configure(with model: InventorySessionViewModel) {
        dateLabel.text = model.dateText
        summaryLabel.text = model.summaryText
        noteLabel.text = model.noteText
    }
}
