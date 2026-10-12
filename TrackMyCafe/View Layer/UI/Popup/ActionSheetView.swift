//
//  ActionSheetView.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 12.10.2026.
//

import TinyConstraints
import UIKit

/// Represents a single action button inside `ActionSheetView`.
struct PopupAction {
    enum Style {
        case `default`
        case destructive
        case cancel
    }

    let title: String
    let style: Style
    let handler: (() -> Void)?

    init(title: String, style: Style = .default, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

/// Custom popup presenting a vertical list of action buttons with a Cancel button.
/// Replaces `UIAlertController` `.actionSheet` for visual consistency.
final class ActionSheetView: UIView {

    // MARK: - Callbacks

    /// Fired when any action (including Cancel) is tapped.
    var onAction: ((PopupAction) -> Void)?

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = AppLabel(style: .callout)
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
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

    // MARK: - Init

    init(title: String?, message: String?, actions: [PopupAction]) {
        super.init(frame: .zero)
        setupUI(title: title, message: message, actions: actions)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(title: String?, message: String?, actions: [PopupAction]) {
        backgroundColor = .clear

        addSubview(stackView)
        stackView.edgesToSuperview()

        if title != nil || message != nil {
            let header = UIView()
            let headerStack = UIStackView()
            headerStack.axis = .vertical
            headerStack.spacing = 2
            headerStack.alignment = .fill
            headerStack.distribution = .fill

            if let title, !title.isEmpty {
                titleLabel.text = title
                headerStack.addArrangedSubview(titleLabel)
            }
            if let message, !message.isEmpty {
                messageLabel.text = message
                headerStack.addArrangedSubview(messageLabel)
            }

            header.addSubview(headerStack)
            headerStack.edgesToSuperview(insets: .init(top: 16, left: 16, bottom: 16, right: 16))
            stackView.addArrangedSubview(header)
            addSeparator()
        }

        for action in actions where action.style != .cancel {
            addButton(for: action)
            addSeparator()
        }

        if let cancelAction = actions.first(where: { $0.style == .cancel }) {
            let spacer = UIView()
            spacer.backgroundColor = UIColor.systemGray6
            spacer.height(8)
            stackView.addArrangedSubview(spacer)
            addButton(for: cancelAction)
        }
    }

    private func addButton(for action: PopupAction) {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        let weight: UIFont.Weight = action.style == .cancel ? .bold : .regular
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: weight)
        switch action.style {
        case .destructive:
            button.tintColor = .systemRed
        default:
            button.tintColor = .systemBlue
        }
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.tag = actionHandlers.count
        button.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        button.height(50)
        actionHandlers.append(action)
        stackView.addArrangedSubview(button)
    }

    private func addSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        separator.height(0.5)
        stackView.addArrangedSubview(separator)
    }

    // MARK: - State

    private var actionHandlers: [PopupAction] = []

    // MARK: - Actions

    @objc private func handleButtonTap(_ sender: UIButton) {
        let index = sender.tag
        guard actionHandlers.indices.contains(index) else { return }
        onAction?(actionHandlers[index])
    }
}
