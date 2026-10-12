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

    // MARK: - SwiftEntryKit Safety Helpers

    /// Workaround for a SwiftEntryKit crash in multi-scene apps.
    ///
    /// During teardown (`displayRollbackWindow`), `entryWindow.windowScene` is
    /// set to `nil` *before* `entryWindow` itself is nilled. On iOS 13+ that can
    /// transiently leave `entryWindow` non-nil while its `rootViewController`
    /// is already `nil`. A concurrent `display(...)` then hits
    /// `setupWindowAndRootVC()` → `entryVC = rootVC!` → fatalError.
    ///
    /// If we detect that broken state we defer the presentation by one run-loop
    /// cycle so teardown can complete.
    private static func safeDisplay(entry view: UIView, using attributes: EKAttributes) {
        if let ekWindow = SwiftEntryKit.window, ekWindow.rootViewController == nil {
            DispatchQueue.main.async {
                SwiftEntryKit.display(entry: view, using: attributes)
            }
        } else {
            SwiftEntryKit.display(entry: view, using: attributes)
        }
    }

    /// Dismisses the currently displayed entry and runs `handler` only after the
    /// exit animation has finished. This guarantees the entry window is fully
    /// torn down before any handler code (which may present another popup) runs.
    private static func dismissThen(_ handler: @escaping () -> Void) {
        SwiftEntryKit.dismiss(.displayed) {
            handler()
        }
    }

    static func showOrderModePopup(
        selectPerOrder: @escaping () -> Void, selectOpenTab: @escaping () -> Void
    ) {
        let popupView = OrderModePopupView()
        popupView.selectPerOrder = {
            dismissThen { selectPerOrder() }
        }
        popupView.selectOpenTab = {
            dismissThen { selectOpenTab() }
        }
        popupView.cancel = {
            SwiftEntryKit.dismiss()
        }

        safeDisplay(entry: popupView, using: PopupFactory.presentAttributes)
    }

    static func showChooseRoleAlert(
        _ roles: [RoleConfig], completion: @escaping (RoleConfig) -> Void
    ) {
        let kHighlightColor = EKColor(rgb: 0x424242)

        let title = EKProperty.LabelContent(
            text: R.string.global.choseSignInRole(),
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: EKColor(UIColor.label),
                alignment: .center
            )
        )

        let simpleMessage = EKSimpleMessage(
            title: title,
            description: .init(text: "", style: .init(font: .systemFont(ofSize: 1), color: .clear)))

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
                dismissThen { completion(role) }
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
        safeDisplay(entry: contentView, using: PopupFactory.presentAttributes)
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
            dismissThen { buttonAction?() }
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
        safeDisplay(entry: contentView, using: PopupFactory.presentAttributes)
    }

    static func showPopup(
        title: String,
        description: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
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
            dismissThen { buttonAction() }
        }

        let closeButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(
                text: R.string.global.cancel(), style: closeButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)
        ) {
            dismissThen { onCancel?() }
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
        safeDisplay(entry: contentView, using: PopupFactory.presentAttributes)
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
            dismissThen { buttonAction() }
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
        safeDisplay(entry: contentView, using: PopupFactory.presentAttributes)
    }

    // MARK: - Input Popup

    /// Presents a custom popup with 1+ text fields. Replaces `UIAlertController`
    /// input alerts for visual consistency across the app.
    static func showInputPopup(
        title: String,
        description: String,
        fields: [InputFieldConfig],
        saveTitle: String = R.string.global.save(),
        onSave: @escaping ([String]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let popupView = InputPopupView(
            title: title,
            description: description,
            fields: fields,
            saveTitle: saveTitle
        )
        popupView.onSave = { values in
            dismissThen { onSave(values) }
        }
        popupView.onCancel = {
            dismissThen { onCancel?() }
        }

        safeDisplay(entry: popupView, using: PopupFactory.presentAttributes)
    }

    // MARK: - Action Sheet

    /// Presents a custom action sheet (vertical list of buttons + Cancel).
    /// Replaces `UIAlertController` `.actionSheet` for visual consistency.
    static func showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [PopupAction]
    ) {
        let popupView = ActionSheetView(title: title, message: message, actions: actions)
        popupView.onAction = { action in
            dismissThen { action.handler?() }
        }

        var attributes = PopupFactory.presentAttributes
        attributes.position = .bottom
        attributes.entranceAnimation = .init(
            translate: .init(
                duration: 0.3,
                anchorPosition: .bottom,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.exitAnimation = .init(
            translate: .init(
                duration: 0.3,
                anchorPosition: .bottom,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.positionConstraints.maxSize = .init(
            width: .constant(value: UIScreen.main.minEdge),
            height: .intrinsic
        )

        safeDisplay(entry: popupView, using: attributes)
    }
}
