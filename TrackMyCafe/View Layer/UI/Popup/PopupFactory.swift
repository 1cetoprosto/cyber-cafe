//
//  PopupFactory.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import SwiftEntryKit
import TinyConstraints
import UIKit

class PopupFactory {

    static var presentAttributes: EKAttributes = {
        var attributes = EKAttributes.float
        attributes.displayMode = .inferred
        attributes.windowLevel = .normal
        attributes.position = .center
        attributes.displayDuration = .infinity
        attributes.entranceAnimation = .init(
            translate: .init(
                duration: 0.65,
                anchorPosition: .bottom,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.exitAnimation = .init(
            translate: .init(
                duration: 0.65,
                anchorPosition: .top,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.popBehavior = .animated(
            animation: .init(
                translate: .init(
                    duration: 0.65,
                    spring: .init(damping: 1, initialVelocity: 0)
                )
            )
        )
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        // Use dynamic system background to support light/dark mode
        attributes.entryBackground = .color(color: EKColor(UIColor.systemBackground))
        attributes.screenBackground = .color(
            color: EKColor(UIColor(white: 50.0 / 255.0, alpha: 0.3)))
        attributes.border = .value(
            color: UIColor(white: 0.6, alpha: 1),
            width: 1
        )
        attributes.shadow = .active(
            with: .init(
                color: .black,
                opacity: 0.3,
                radius: 3
            )
        )
        attributes.scroll = .enabled(
            swipeable: false,
            pullbackAnimation: .jolt
        )
        attributes.statusBar = .light
        attributes.positionConstraints.keyboardRelation = .bind(
            offset: .init(
                bottom: 15,
                screenEdgeResistance: 0
            )
        )
        attributes.positionConstraints.maxSize = .init(
            width: .constant(value: UIScreen.main.minEdge),
            height: .intrinsic
        )
        return attributes
    }()

    static func showOrderModePopup(
        selectPerOrder: @escaping () -> Void, selectOpenTab: @escaping () -> Void
    ) {
        let popupView = OrderModePopupView()
        popupView.selectPerOrder = {
            SwiftEntryKit.dismiss()
            selectPerOrder()
        }
        popupView.selectOpenTab = {
            SwiftEntryKit.dismiss()
            selectOpenTab()
        }
        popupView.cancel = {
            SwiftEntryKit.dismiss()
        }

        SwiftEntryKit.display(entry: popupView, using: PopupFactory.presentAttributes)
    }

    static func showChooseRoleAlert(_ roles: [RoleConfig], completion: @escaping (RoleConfig) -> Void) {
        let kHighlightColor = EKColor(rgb: 0x424242)

        let title = EKProperty.LabelContent(
            text: R.string.global.choseSignInRole(),
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: EKColor(UIColor.label),
                alignment: .center
            )
        )

        let simpleMessage = EKSimpleMessage(title: title, description: .init(text: "", style: .init(font: .systemFont(ofSize: 1), color: .clear)))

        var buttons: [EKProperty.ButtonContent] = []

        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let optionButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.systemBlue)
        )

        for role in roles {
            let button = EKProperty.ButtonContent(
                label: EKProperty.LabelContent(text: role.role.name, style: optionButtonLabelStyle),
                backgroundColor: .clear,
                highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
            ) {
                completion(role)
                SwiftEntryKit.dismiss()
            }
            buttons.append(button)
        }

        let buttonsBarContent = EKProperty.ButtonBarContent(
            with: buttons,
            separatorColor: EKColor(red: 230, green: 230, blue: 230),
            horizontalDistributionThreshold: 1,
            expandAnimatedly: false
        )

        let alertMessage = EKAlertMessage(
            simpleMessage: simpleMessage,
            buttonBarContent: buttonsBarContent
        )

        let contentView = EKAlertMessageView(with: alertMessage)
        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
    }

    static func showPopup(title: String, description: String, buttonAction: (() -> Void)? = nil) {
        let kHighlightColor = EKColor(rgb: 0x424242)

        let title = EKProperty.LabelContent(
            text: title,
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: EKColor(UIColor.label),
                alignment: .center
            )
        )

        let text = description
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: EKColor(UIColor.secondaryLabel),
                alignment: .center
            )
        )

        let simpleMessage = EKSimpleMessage(title: title, description: description)

        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)

        let optionButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.systemBlue)
        )

        let actionButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(
                text: R.string.global.actionOk(), style: optionButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
        ) {
            buttonAction?()
            SwiftEntryKit.dismiss()
        }

        let buttonsBarContent = EKProperty.ButtonBarContent(
            with: [actionButton],
            separatorColor: EKColor(red: 230, green: 230, blue: 230),
            horizontalDistributionThreshold: 2,
            expandAnimatedly: false
        )
        let alertMessage = EKAlertMessage(
            simpleMessage: simpleMessage,
            buttonBarContent: buttonsBarContent
        )
        let contentView = EKAlertMessageView(with: alertMessage)
        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
    }

    static func showPopup(
        title: String, description: String, buttonTitle: String, buttonAction: @escaping () -> Void
    ) {
        let kHighlightColor = EKColor(rgb: 0x424242)

        let title = EKProperty.LabelContent(
            text: title,
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: EKColor(UIColor.label),
                alignment: .center
            )
        )

        let text = description
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: EKColor(UIColor.secondaryLabel),
                alignment: .center
            )
        )

        let simpleMessage = EKSimpleMessage(title: title, description: description)

        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)

        let optionButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.systemBlue)
        )
        let closeButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.systemRed)
        )

        let actionButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: buttonTitle, style: optionButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
        ) {
            buttonAction()
            SwiftEntryKit.dismiss()
        }

        let closeButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(
                text: R.string.global.cancel(), style: closeButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
        ) {
            SwiftEntryKit.dismiss()
        }

        let buttonsBarContent = EKProperty.ButtonBarContent(
            with: [closeButton, actionButton],
            separatorColor: EKColor(red: 230, green: 230, blue: 230),
            horizontalDistributionThreshold: 2,
            expandAnimatedly: false
        )
        let alertMessage = EKAlertMessage(
            simpleMessage: simpleMessage,
            buttonBarContent: buttonsBarContent
        )
        let contentView = EKAlertMessageView(with: alertMessage)
        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
    }

    static func showDestructivePopup(
        title: String, description: String, buttonTitle: String, buttonAction: @escaping () -> Void
    ) {
        let kHighlightColor = EKColor(rgb: 0x424242)

        let title = EKProperty.LabelContent(
            text: title,
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: EKColor(UIColor.label),
                alignment: .center
            )
        )

        let text = description
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: EKColor(UIColor.secondaryLabel),
                alignment: .center
            )
        )

        let simpleMessage = EKSimpleMessage(title: title, description: description)

        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)

        let destructiveButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.systemRed)
        )
        let cancelButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.systemBlue)
        )

        let actionButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: buttonTitle, style: destructiveButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
        ) {
            buttonAction()
            SwiftEntryKit.dismiss()
        }

        let closeButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(
                text: R.string.global.cancel(), style: cancelButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
        ) {
            SwiftEntryKit.dismiss()
        }

        let buttonsBarContent = EKProperty.ButtonBarContent(
            with: [closeButton, actionButton],
            separatorColor: EKColor(red: 230, green: 230, blue: 230),
            horizontalDistributionThreshold: 2,
            expandAnimatedly: false
        )
        let alertMessage = EKAlertMessage(
            simpleMessage: simpleMessage,
            buttonBarContent: buttonsBarContent
        )
        let contentView = EKAlertMessageView(with: alertMessage)
        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
    }
}

private class OrderModePopupView: UIView {

    var selectPerOrder: (() -> Void)?
    var selectOpenTab: (() -> Void)?
    var cancel: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.global.orderEntryModeTitle()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
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

        // Title Container
        let titleContainer = UIView()
        titleContainer.addSubview(titleLabel)
        titleLabel.edgesToSuperview(insets: .init(top: 20, left: 16, bottom: 10, right: 16))
        stackView.addArrangedSubview(titleContainer)

        // Description Container
        let descContainer = UIView()
        descContainer.addSubview(descriptionLabel)
        descriptionLabel.edgesToSuperview(insets: .init(top: 0, left: 24, bottom: 24, right: 24))
        setupDescriptionText()
        stackView.addArrangedSubview(descContainer)

        // Buttons
        addSeparator()
        addButton(title: R.string.global.orderModePerOrder(), action: #selector(handlePerOrder))
        addSeparator()
        addButton(title: R.string.global.orderModeOpenTab(), action: #selector(handleOpenTab))
        addSeparator()
        addButton(title: R.string.global.cancel(), isBold: true, action: #selector(handleCancel))
    }

    private func setupDescriptionText() {
        let text = NSMutableAttributedString()

        // Classic Mode
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

        // Simplified Mode
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

        // Paragraph Style
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
        button.height(50)  // Increased height for better touch target

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
