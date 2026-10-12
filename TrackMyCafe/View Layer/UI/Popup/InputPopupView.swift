//
//  InputPopupView.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 12.10.2026.
//

import TinyConstraints
import UIKit

// MARK: - Input Field Configuration

/// Configuration for a single text field inside `InputPopupView`.
struct InputFieldConfig {
    let placeholder: String
    let keyboardType: UIKeyboardType
    let initialText: String?
    let isSecureTextEntry: Bool

    init(
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        initialText: String? = nil,
        isSecureTextEntry: Bool = false
    ) {
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.initialText = initialText
        self.isSecureTextEntry = isSecureTextEntry
    }
}

// MARK: - Input Popup View

/// Custom popup for text input. Renders 1+ fields in the app's visual style.
/// Used by `PopupFactory.showInputPopup`.
final class InputPopupView: UIView {

    // MARK: - Callbacks

    var onSave: (([String]) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = AppLabel(style: .headline)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = AppLabel(style: .body)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var fieldsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 12
        return stack
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 0
        return stack
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 16
        return stack
    }()

    private var textFields: [UITextField] = []

    // MARK: - Init

    init(title: String, description: String, fields: [InputFieldConfig], saveTitle: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description
        setupUI(fields: fields, saveTitle: saveTitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(fields: [InputFieldConfig], saveTitle: String) {
        backgroundColor = .clear

        addSubview(contentStackView)
        contentStackView.edgesToSuperview(insets: .init(top: 20, left: 16, bottom: 12, right: 16))

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)

        for config in fields {
            let fieldView = makeFieldContainer(config: config)
            fieldsStackView.addArrangedSubview(fieldView)
        }
        contentStackView.addArrangedSubview(fieldsStackView)

        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        separator.height(0.5)
        contentStackView.addArrangedSubview(separator)

        let cancelButton = makeButton(
            title: R.string.global.cancel(),
            isBold: false,
            action: #selector(handleCancel)
        )
        let saveButton = makeButton(
            title: saveTitle,
            isBold: true,
            action: #selector(handleSave)
        )

        buttonsStackView.addArrangedSubview(cancelButton)
        buttonsStackView.addArrangedSubview(saveButton)
        contentStackView.addArrangedSubview(buttonsStackView)
    }

    private func makeFieldContainer(config: InputFieldConfig) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.Main.secondaryBackground
        container.layer.cornerRadius = 10

        let textField = UITextField()
        textField.font = Typography.body
        textField.textColor = UIColor.Main.text
        textField.placeholder = config.placeholder
        textField.keyboardType = config.keyboardType
        textField.isSecureTextEntry = config.isSecureTextEntry
        textField.text = config.initialText
        textField.borderStyle = .none
        textField.returnKeyType = .done

        switch config.keyboardType {
        case .emailAddress, .URL:
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        case .decimalPad, .numberPad:
            textField.textAlignment = .right
        default:
            break
        }

        container.addSubview(textField)
        textField.horizontalToSuperview(insets: .horizontal(12))
        textField.verticalToSuperview(insets: .vertical(10))

        textFields.append(textField)
        return container
    }

    private func makeButton(title: String, isBold: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: isBold ? .bold : .regular)
        button.tintColor = UIColor.Main.text
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.addTarget(self, action: action, for: .touchUpInside)
        button.height(44)
        return button
    }

    // MARK: - Actions

    @objc private func handleSave() {
        let values = textFields.map { $0.text ?? "" }
        onSave?(values)
    }

    @objc private func handleCancel() {
        onCancel?()
    }
}
