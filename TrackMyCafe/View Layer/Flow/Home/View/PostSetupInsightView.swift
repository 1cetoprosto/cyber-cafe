//
//  PostSetupInsightView.swift
//  TrackMyCafe
//

import TinyConstraints
import UIKit

// MARK: - PostSetupInsightView

/// One-time Home card after first-run: scale tip, daily habit, Settings mention.
final class PostSetupInsightView: UIView {

    var onDismiss: (() -> Void)?

    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.applyCafeSoftCardStyle()
        return view
    }()

    private let titleLabel: UILabel = {
        let label = AppLabel(style: .bodyDemiBold)
        label.apply(.bodyDemiBold)
        label.textColor = UIColor.Main.text
        label.numberOfLines = 0
        label.text = R.string.global.postSetupInsightTitle()
        return label
    }()

    private let scaleLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = UIColor.Main.text.withAlphaComponent(0.75)
        label.numberOfLines = 0
        label.text = R.string.global.postSetupInsightScale()
        return label
    }()

    private let habitLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = UIColor.Main.text.withAlphaComponent(0.75)
        label.numberOfLines = 0
        label.text = R.string.global.postSetupInsightHabit()
        return label
    }()

    private let settingsLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = UIColor.Main.text.withAlphaComponent(0.75)
        label.numberOfLines = 0
        label.text = R.string.global.postSetupInsightSettings()
        return label
    }()

    private lazy var dismissButton: DefaultButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.postSetupInsightDismiss(), for: .normal)
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "postSetupInsightDismiss"
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(container)

        let textStack = UIStackView(arrangedSubviews: [
            titleLabel, scaleLabel, habitLabel, settingsLabel,
        ])
        textStack.axis = .vertical
        textStack.spacing = UIConstants.smallSpacing

        let contentStack = UIStackView(arrangedSubviews: [textStack, dismissButton])
        contentStack.axis = .vertical
        contentStack.spacing = UIConstants.standardPadding

        container.addSubview(contentStack)

        container.edgesToSuperview()
        contentStack.edgesToSuperview(
            insets: UIEdgeInsets(
                top: UIConstants.standardPadding,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding,
                right: UIConstants.standardPadding
            )
        )
        dismissButton.height(UIConstants.buttonHeight)
    }

    @objc private func dismissTapped() {
        onDismiss?()
    }
}
