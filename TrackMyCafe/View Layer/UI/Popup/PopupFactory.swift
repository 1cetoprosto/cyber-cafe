//
//  PopupFactory.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import UIKit
import SwiftEntryKit

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
        attributes.entryBackground = .color(color: .standardBackground)
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 50.0/255.0, alpha: 0.3)))
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
    
    static func showPopup(title: String, description: String, buttonAction: (() -> Void)? = nil) {
        let kHighlightColor = EKColor(rgb: 0x424242)
        
        let title = EKProperty.LabelContent(
            text: title,
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: .black,
                alignment: .center
            )
        )
        
        let text = description
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: .black,
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
            label: EKProperty.LabelContent(text: R.string.global.actionOk(), style: optionButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
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
    
    static func showPopup(title: String, description: String, buttonTitle: String, buttonAction: @escaping () -> Void) {
        let kHighlightColor = EKColor(rgb: 0x424242)
        
        let title = EKProperty.LabelContent(
            text: title,
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: .black,
                alignment: .center
            )
        )
        
        let text = description
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: .black,
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
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
            buttonAction()
            SwiftEntryKit.dismiss()
        }
        
        let closeButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: R.string.global.cancel(), style: closeButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
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
    
    static func showChooseRoleAlert(_ roles: [RoleConfig], choose: @escaping (RoleConfig) -> Void) {
        let kHighlightColor = EKColor(rgb: 0x424242)
        
        let title = EKProperty.LabelContent(
            text: R.string.auth.signInHow(),
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: .black,
                alignment: .center
            )
        )
        
        let text = R.string.global.choseSignInRole()
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: .black,
                alignment: .center
            )
        )
        let simpleMessage = EKSimpleMessage(
            title: title,
            description: description
        )
        
        var buttons = [EKProperty.ButtonContent]()
        
        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let optionButtonLabelStyle = EKProperty.LabelStyle(
            font: buttonFont,
            color: EKColor(.black)
        )
        
        roles.forEach { role in
            let optionButtonLabel = EKProperty.LabelContent(
                text: role.role.name.uppercased(),
                style: optionButtonLabelStyle
            )
            let optionButton = EKProperty.ButtonContent(
                label: optionButtonLabel,
                backgroundColor: .clear,
                highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
                choose(role)
                SwiftEntryKit.dismiss()
            }
            buttons.append(optionButton)
        }
        
        // Generate the content
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
    
    static func showChoosePrintType(allowDoctor: Bool, _ completion: @escaping (_ forTechinican: Bool) -> Void) {
        let kHighlightColor = EKColor(rgb: 0x424242)
        
        let title = EKProperty.LabelContent(
            text: R.string.global.chose(),
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: .black,
                alignment: .center
            )
        )
        
        let text = R.string.global.printForWhom()
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: .black,
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
        
        var actionButtons = [EKProperty.ButtonContent]()
        
        if allowDoctor {
            let doctorButton = EKProperty.ButtonContent(
                label: EKProperty.LabelContent(text: R.string.global.printForDoctor(), style: optionButtonLabelStyle),
                backgroundColor: .clear,
                highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
                completion(false)
                SwiftEntryKit.dismiss()
            }
            actionButtons.append(doctorButton)
        }
        
        let technicianButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: R.string.global.printForTechnician(), style: optionButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
            completion(true)
            SwiftEntryKit.dismiss()
        }
        actionButtons.append(technicianButton)
        
        let closeButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: R.string.global.cancel(), style: closeButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
            SwiftEntryKit.dismiss()
        }
        actionButtons.append(closeButton)
        
        let buttonsBarContent = EKProperty.ButtonBarContent(
            with: actionButtons,
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
    
    static func showPopup(title: String, description: String, buttonTitle: String, buttonAction: @escaping () -> Void, startOverAction: @escaping () -> Void, cancelAction: (() -> Void)? = nil) {
        let kHighlightColor = EKColor(rgb: 0x424242)
        
        let title = EKProperty.LabelContent(
            text: title,
            style: .init(
                font: .systemFont(ofSize: 17, weight: .medium),
                color: .black,
                alignment: .center
            )
        )
        
        let text = description
        let description = EKProperty.LabelContent(
            text: text,
            style: .init(
                font: .systemFont(ofSize: 14),
                color: .black,
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
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
            buttonAction()
            SwiftEntryKit.dismiss()
        }
        
        let noButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: R.string.global.startOver(), style: optionButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
                startOverAction()
                SwiftEntryKit.dismiss()
            }
        
        let cancelButton = EKProperty.ButtonContent(
            label: EKProperty.LabelContent(text: R.string.global.cancel(), style: closeButtonLabelStyle),
            backgroundColor: .clear,
            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
            cancelAction?()
            SwiftEntryKit.dismiss()
        }
        
        let buttonsBarContent = EKProperty.ButtonBarContent(
            with: [cancelButton, noButton, actionButton],
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

//    static func showChoosePatientAlert(_ patients: [OrderPatient], save: @escaping (OrderPatient?) -> Void) {
//        let kHighlightColor = EKColor(rgb: 0x424242)
//        
//        let title = EKProperty.LabelContent(
//            text: R.string.global.chosePatient(),
//            style: .init(
//                font: .systemFont(ofSize: 17, weight: .medium),
//                color: .black,
//                alignment: .center
//            )
//        )
//        let text = R.string.global.chosePatientInfo()
//        let description = EKProperty.LabelContent(
//            text: text,
//            style: .init(
//                font: .systemFont(ofSize: 14),
//                color: .black,
//                alignment: .center
//            )
//        )
//        let simpleMessage = EKSimpleMessage(
//            title: title,
//            description: description
//        )
//        
//        var buttons = [EKProperty.ButtonContent]()
//        
//        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)
//        let optionButtonLabelStyle = EKProperty.LabelStyle(
//            font: buttonFont,
//            color: EKColor(.systemBlue)
//        )
//        
//        let closeButtonLabelStyle = EKProperty.LabelStyle(
//            font: buttonFont,
//            color: EKColor(.systemRed)
//        )
//        
//        patients.forEach { patient in
//            var title = ""
//            if let name = patient.name {
//                title += "\(R.string.global.patient()): \(name)"
//            }
//            if let age = patient.age, age > 0 {
//                title += "; \(R.string.global.age()): \(age)"
//            }
//            if title.count > 0 {
//                title += "; \(R.string.global.patientGender()): \(patient.gender.name)"
//                let optionButtonLabel = EKProperty.LabelContent(
//                    text: title,
//                    style: optionButtonLabelStyle
//                )
//                let optionButton = EKProperty.ButtonContent(
//                    label: optionButtonLabel,
//                    backgroundColor: .clear,
//                    highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
//                    save(patient)
//                    SwiftEntryKit.dismiss()
//                }
//                buttons.append(optionButton)
//            } else {
//                title = R.string.global.deletePatientInfo()
//                let clearButtonLabel = EKProperty.LabelContent(
//                    text: title,
//                    style: closeButtonLabelStyle
//                )
//                let clearButton = EKProperty.ButtonContent(
//                    label: clearButtonLabel,
//                    backgroundColor: .clear,
//                    highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
//                    save(nil)
//                    SwiftEntryKit.dismiss()
//                }
//                buttons.append(clearButton)
//            }
//        }
//        
//        let closeButtonLabel = EKProperty.LabelContent(
//            text: R.string.global.cancel(),
//            style: closeButtonLabelStyle
//        )
//        let closeButton = EKProperty.ButtonContent(
//            label: closeButtonLabel,
//            backgroundColor: .clear,
//            highlightedBackgroundColor: kHighlightColor.with(alpha: 0.05)) {
//            SwiftEntryKit.dismiss()
//        }
//        
//        buttons.append(closeButton)
//        
//        // Generate the content
//        let buttonsBarContent = EKProperty.ButtonBarContent(
//            with: buttons,
//            separatorColor: EKColor(red: 230, green: 230, blue: 230),
//            horizontalDistributionThreshold: 1,
//            expandAnimatedly: false
//        )
//        let alertMessage = EKAlertMessage(
//            simpleMessage: simpleMessage,
//            buttonBarContent: buttonsBarContent
//        )
//        let contentView = EKAlertMessageView(with: alertMessage)
//        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
//    }
    
//    static func showEditPricePopup(title: String, info: String, placeholder: String, text: String, keyboardType: UIKeyboardType, completion: @escaping (String?) -> Void) {
//        let contentView = DTFormMessageView(title: title, info: info, placeholder: placeholder, text: text, keyboardType: keyboardType, completion: completion)
//        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
//    }
    
//    static func confirmPaymentPopup(_ items: [DoctorOrdersInfo], total: String, completion: @escaping (Bool) -> Void) {
//        let contentView = ConfirmPaymentPopup(items, total: total, completion: completion)
//        
//        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
//    }
    
//    static func showElementCountPopup(title: String,
//                                      info: String,
//                                      infoColor: UIColor,
//                                      placeholder: String,
//                                      text: String,
//                                      completion: @escaping (String?) -> Void) {
//        let contentView = DTFormMessageView(title: title,
//                                            info: info,
//                                            infoColor: infoColor,
//                                            placeholder: placeholder,
//                                            text: text,
//                                            completion: completion)
//        
//        SwiftEntryKit.display(entry: contentView, using: PopupFactory.presentAttributes)
//    }
}

