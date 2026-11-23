//
//  AppProgressHUD.swift
//  TrackMyCafe
//
//  Lightweight UIKit replacement for SVProgressHUD.
//

import UIKit

// MARK: - AppProgressHUD

enum AppProgressHUD {

    // MARK: - Configuration

    private(set) static var minimumDismissTimeInterval: TimeInterval = 1.0
    private(set) static var dimColor: UIColor = UIColor(white: 0, alpha: 0.4)

    static func configure() {
        minimumDismissTimeInterval = 1.0
        dimColor = UIColor(white: 0, alpha: 0.4)
    }

    // MARK: - Public API

    static func show() {
        show(withStatus: nil)
    }

    static func show(withStatus status: String?) {
        performOnMain {
            cancelScheduledDismiss()
            presenter.show(mode: .loading, status: status)
        }
    }

    static func show(_ show: Bool) {
        if show {
            Self.show()
        } else {
            dismiss()
        }
    }

    static func dismiss() {
        performOnMain {
            cancelScheduledDismiss()
            presenter.dismiss()
        }
    }

    static func showSuccess(withStatus status: String?) {
        performOnMain {
            cancelScheduledDismiss()
            presenter.show(mode: .success, status: status)
            scheduleAutoDismiss()
        }
    }

    static func showSuccess() {
        showSuccess(withStatus: nil)
    }

    static func showError(withStatus status: String?) {
        performOnMain {
            cancelScheduledDismiss()
            presenter.show(mode: .error, status: status)
            scheduleAutoDismiss()
        }
    }

    // MARK: - Private

    private static let presenter = AppProgressHUDPresenter()
    private static var dismissWorkItem: DispatchWorkItem?

    private static func performOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private static func scheduleAutoDismiss() {
        let workItem = DispatchWorkItem {
            presenter.dismiss()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDismissTimeInterval, execute: workItem)
    }

    private static func cancelScheduledDismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }
}

// MARK: - Mode

private enum AppProgressHUDMode {
    case loading
    case success
    case error
}

// MARK: - Presenter

private final class AppProgressHUDPresenter {

    private weak var overlayView: AppProgressHUDOverlayView?

    func show(mode: AppProgressHUDMode, status: String?) {
        guard let window = keyWindow() else { return }

        let overlay: AppProgressHUDOverlayView
        if let existing = overlayView, existing.superview === window {
            overlay = existing
        } else {
            overlayView?.removeFromSuperview()
            let created = AppProgressHUDOverlayView()
            created.translatesAutoresizingMaskIntoConstraints = false
            // Clear mask: touches pass through (matches SVProgressHUD .clear).
            created.isUserInteractionEnabled = false
            window.addSubview(created)
            NSLayoutConstraint.activate([
                created.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                created.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                created.topAnchor.constraint(equalTo: window.topAnchor),
                created.bottomAnchor.constraint(equalTo: window.bottomAnchor)
            ])
            overlayView = created
            overlay = created
        }

        overlay.apply(mode: mode, status: status, dimColor: AppProgressHUD.dimColor)
        overlay.alpha = 1
    }

    func dismiss() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - Overlay View

private final class AppProgressHUDOverlayView: UIView {

    private let dimView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let symbolImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        return imageView
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private var statusLabelWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func apply(mode: AppProgressHUDMode, status: String?, dimColor: UIColor) {
        dimView.backgroundColor = dimColor
        cardView.backgroundColor = UIColor.Main.secondaryBackground
        statusLabel.textColor = UIColor.Main.text
        activityIndicator.color = UIColor.Main.text

        let trimmed = status?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasStatus = !(trimmed?.isEmpty ?? true)
        statusLabel.text = trimmed
        statusLabel.isHidden = !hasStatus

        switch mode {
        case .loading:
            symbolImageView.isHidden = true
            symbolImageView.image = nil
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        case .success:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            symbolImageView.isHidden = false
            symbolImageView.tintColor = UIColor.Semantic.positive
            symbolImageView.image = UIImage(systemName: "checkmark.circle.fill")
        case .error:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            symbolImageView.isHidden = false
            symbolImageView.tintColor = UIColor.Semantic.negative
            symbolImageView.image = UIImage(systemName: "xmark.circle.fill")
        }
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(dimView)
        addSubview(cardView)
        cardView.addSubview(stackView)
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(symbolImageView)
        stackView.addArrangedSubview(statusLabel)

        let widthConstraint = statusLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 220)
        statusLabelWidthConstraint = widthConstraint

        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),

            symbolImageView.widthAnchor.constraint(equalToConstant: 44),
            symbolImageView.heightAnchor.constraint(equalToConstant: 44),

            widthConstraint
        ])
    }
}
