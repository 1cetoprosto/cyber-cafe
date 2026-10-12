//
//  OrderModePopupView.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 12.10.2026.
//

import TinyConstraints
import UIKit

/// Custom popup for choosing the order entry mode (per-order or open tab).
/// Used by `PopupFactory.showOrderModePopup`.
final class OrderModePopupView: UIView {

    var selectPerOrder: (() -> Void)?
    var selectOpenTab: (() -> Void)?
    var cancel: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.text = R.string.global.orderEntryModeTitle()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 0
        return stack
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(stackView)
        stackView.edgesToSuperview()

        let titleContainer = UIView()
        titleContainer.addSubview(titleLabel)
        titleLabel.edgesToSuperview(insets: .init(top: 20, left: 16, bottom: 10, right: 16))
        stackView.addArrangedSubview(titleContainer)

        let descContainer = UIView()
        descContainer.addSubview(descriptionLabel)
        descriptionLabel.edgesToSuperview(insets: .init(top: 0, left: 24, bottom: 24, right: 24))
        setupDescriptionText()
        stackView.addArrangedSubview(descContainer)

        addSeparator()
        addButton(title: R.string.global.orderModePerOrder(), action: #selector(handlePerOrder))
        addSeparator()
        addButton(title: R.string.global.orderModeOpenTab(), action: #selector(handleOpenTab))
        addSeparator()
        addButton(title: R.string.global.cancel(), isBold: true, action: #selector(handleCancel))
    }

    private func setupDescriptionText() {
        let text = NSMutableAttributedString()

        let classicTitle = NSAttributedString(
            string: R.string.global.orderModePerOrder() + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.label,
            ]
        )
        let classicDesc = NSAttributedString(
            string: R.string.global.orderModePerOrderDescription() + "\n\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
            ]
        )

        let simpleTitle = NSAttributedString(
            string: R.string.global.orderModeOpenTab() + "\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.label,
            ]
        )
        let simpleDesc = NSAttributedString(
            string: R.string.global.orderModeOpenTabDescription(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
            ]
        )

        text.append(classicTitle)
        text.append(classicDesc)
        text.append(simpleTitle)
        text.append(simpleDesc)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        text.addAttribute(
            .paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.length)
        )

        descriptionLabel.attributedText = text
    }

    private func addButton(title: String, isBold: Bool = false, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: isBold ? .bold : .regular)
        button.tintColor = .label

        button.addTarget(self, action: action, for: .touchUpInside)
        button.height(50)

        stackView.addArrangedSubview(button)
    }

    private func addSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        separator.height(0.5)
        stackView.addArrangedSubview(separator)
    }

    @objc private func handlePerOrder() { selectPerOrder?() }
    @objc private func handleOpenTab() { selectOpenTab?() }
    @objc private func handleCancel() { cancel?() }
}
