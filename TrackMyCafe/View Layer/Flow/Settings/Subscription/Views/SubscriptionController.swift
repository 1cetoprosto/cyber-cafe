//
//  SubscriptionController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import StoreKit
import SwiftyStoreKit
import TinyConstraints
import UIKit
import SafariServices

class SubscriptionController: UIViewController, Loggable {

    // MARK: - Properties
    var onSubscriptionSuccess: (() -> Void)?
    var onSkip: (() -> Void)?
    private var products = [SKProduct]()
    private var selectedProduct: SKProduct?
    private var isEligibleForTrial = false

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainStackView = UIStackView()

    private let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true

        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            imageView.image = UIImage(named: lastIcon)
        }

        if imageView.image == nil {
            imageView.image = UIImage(systemName: "crown.fill")
            imageView.tintColor = .systemOrange
        }
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.global.appName()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let proTagLabel: UILabel = {
        let label = UILabel()
        label.text = "PRO"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemOrange
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.global.subscriptionSubtitle()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let featuresContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let featuresStackView = UIStackView()

    private let trialBadge: UILabel = {
        let label = UILabel()
        label.text = R.string.global.trialBadgeText(14)
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemOrange
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.loading(), for: .normal)
        button.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        let title = NSLocalizedString("continue_read_only", value: "Continue in Read-Only Mode", comment: "")
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(skipAction), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private let termsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let footerStackView = UIStackView()

    // MARK: - Init

    init(_ text: String) {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()

        NotificationCenter.default.addObserver(
            self, selector: #selector(updateUI), name: .subscriptionInfoReload, object: nil)

        Task { [weak self] in
            guard let self else { return }
            let isPro = await IAPManager.shared.refreshProStatusUsingStoreKit2()
            await MainActor.run {
                self.logger.debug("SubscriptionController refreshed isPro: \(isPro)")
                if isPro {
                    if let onSuccess = self.onSubscriptionSuccess {
                        onSuccess()
                        return
                    }
                    self.setupActiveSubscriptionUI()
                } else {
                    self.fetchProducts()
                }
            }
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        titleLabel.textColor = UIColor.Main.text
        subtitleLabel.textColor = UIColor.Main.secondaryText
        featuresContainer.backgroundColor = UIColor.TableView.cellBackground
        skipButton.setTitleColor(UIColor.Main.secondaryText, for: .normal)
        termsLabel.textColor = UIColor.Main.secondaryText

        title = ""

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(mainStackView)
        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.alignment = .fill

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, proTagLabel])
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center

        proTagLabel.width(40)
        proTagLabel.height(24)

        let headerStack = UIStackView(arrangedSubviews: [headerImageView, titleStack, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .center

        setupFeatures()

        featuresContainer.addSubview(featuresStackView)
        featuresStackView.edgesToSuperview(insets: .init(top: 16, left: 16, bottom: 16, right: 16))

        setupFooterLinks()

        mainStackView.addArrangedSubview(headerStack)
        mainStackView.addArrangedSubview(featuresContainer)
        mainStackView.addArrangedSubview(trialBadge)
        mainStackView.addArrangedSubview(actionButton)
        mainStackView.addArrangedSubview(skipButton)
        mainStackView.addArrangedSubview(termsLabel)
        mainStackView.addArrangedSubview(footerStackView)

        mainStackView.setCustomSpacing(40, after: headerStack)
        mainStackView.setCustomSpacing(30, after: featuresContainer)
        mainStackView.setCustomSpacing(8, after: trialBadge)
        mainStackView.setCustomSpacing(10, after: actionButton)
        mainStackView.setCustomSpacing(10, after: skipButton)
    }

    private func setupFeatures() {
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 16

        let features = [
            R.string.global.subscriptionFeature1(),
            R.string.global.subscriptionFeature2(),
            R.string.global.subscriptionFeature3(),
            R.string.global.subscriptionFeature4(),
            R.string.global.subscriptionFeature5()
        ]

        for (index, feature) in features.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center

            let iconContainer = UIView()
            iconContainer.backgroundColor = .systemOrange
            iconContainer.layer.cornerRadius = 10
            iconContainer.clipsToBounds = true

            let icon = UIImageView(image: UIImage(systemName: "checkmark"))
            icon.tintColor = .white
            icon.contentMode = .scaleAspectFit

            iconContainer.addSubview(icon)
            icon.centerInSuperview()
            icon.width(10)
            icon.height(10)

            iconContainer.width(20)
            iconContainer.height(20)

            let label = UILabel()
            label.text = feature
            label.font = .systemFont(ofSize: 16)
            label.textColor = UIColor.Main.text
            label.numberOfLines = 0

            row.addArrangedSubview(iconContainer)
            row.addArrangedSubview(label)

            featuresStackView.addArrangedSubview(row)

            if index < features.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                separator.height(0.5)
                featuresStackView.addArrangedSubview(separator)
            }
        }
    }

    private func setupFooterLinks() {
        footerStackView.axis = .vertical
        footerStackView.spacing = 8
        footerStackView.alignment = .center

        let restoreButton = createFooterButton(title: R.string.global.restorePurchases(), action: #selector(restoreAction))

        let policyStack = UIStackView()
        policyStack.axis = .horizontal
        policyStack.spacing = 8

        let privacyButton = createFooterButton(title: R.string.global.privacyPolicy(), action: #selector(openPrivacy))
        let termsButton = createFooterButton(title: R.string.global.termsOfUse(), action: #selector(openTerms))
        let separator = createSeparator()

        policyStack.addArrangedSubview(privacyButton)
        policyStack.addArrangedSubview(separator)
        policyStack.addArrangedSubview(termsButton)

        footerStackView.addArrangedSubview(restoreButton)
        footerStackView.addArrangedSubview(policyStack)
    }

    private func createSeparator() -> UILabel {
        let label = UILabel()
        label.text = "|"
        label.textColor = UIColor.Main.secondaryText
        label.font = .systemFont(ofSize: 12)
        return label
    }

    private func createFooterButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(UIColor.Main.secondaryText, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func setupConstraints() {
        scrollView.edgesToSuperview()
        contentView.edges(to: scrollView)
        contentView.widthToSuperview()

        mainStackView.edgesToSuperview(insets: .init(top: 60, left: 20, bottom: 40, right: 20))

        headerImageView.size(CGSize(width: 80, height: 80))
        actionButton.height(50)

        trialBadge.width(160)
        trialBadge.height(26)
    }

    // MARK: - Logic

    private func fetchProducts() {
        actionButton.isEnabled = false
        actionButton.setTitle(R.string.global.loading(), for: .normal)

        IAPManager.shared.getProducts { [weak self] (products) in
            guard let self = self else { return }

            guard let products = products, !products.isEmpty else {
                DispatchQueue.main.async {
                    self.actionButton.setTitle(R.string.global.subscriptionBannerAction(), for: .normal)
                    self.actionButton.isEnabled = true
                }
                return
            }

            self.products = products
            self.selectedProduct = SubscriptionPresenter.shared.findBestProduct(in: products)

            Task { [weak self] in
                guard let self else { return }
                let hasKnownHistory: Bool = {
                    if IAPManager.shared.nextPaymentDate != nil { return true }
                    guard let subscription = RequestManager.shared.subscription else { return false }
                    if subscription.nextPaymentDate != nil { return true }
                    if (subscription.transactionId ?? subscription.originTransactionId) != nil { return true }
                    return false
                }()

                await MainActor.run {
                    self.isEligibleForTrial = false
                    self.updateProductUI()
                }

                if hasKnownHistory {
                    return
                }

                let eligible = await IAPManager.shared.isEligibleForTrialUsingBestEffort()
                await MainActor.run {
                    self.isEligibleForTrial = eligible
                    self.updateProductUI()
                }
            }
        }
    }

    private func updateProductUI() {
        guard let product = selectedProduct else { return }

        actionButton.isEnabled = true

        let displayInfo = SubscriptionPresenter.shared.getDisplayInfo(
            for: product,
            isEligibleForTrial: isEligibleForTrial
        )

        trialBadge.isHidden = !displayInfo.isTrial
        actionButton.setTitle(displayInfo.buttonTitle, for: .normal)
        termsLabel.text = displayInfo.termsText

        if IAPManager.shared.isProPlan == true {
            setupActiveSubscriptionUI()
        } else {
            setupInactiveSubscriptionUI()
        }
    }

    private func setupInactiveSubscriptionUI() {
        featuresContainer.isHidden = false
        termsLabel.isHidden = false

        if let expireDate = IAPManager.shared.nextPaymentDate, expireDate < Date() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let expiredText = R.string.global.subscriptionExpiredSubtitle()
            subtitleLabel.text = "\(expiredText) \(formatter.string(from: expireDate))"
            subtitleLabel.textColor = .systemRed
        } else {
            subtitleLabel.text = R.string.global.subscriptionSubtitle()
            subtitleLabel.textColor = UIColor.Main.secondaryText
        }
    }

    private func setupActiveSubscriptionUI() {
        logger.debug("setupActiveSubscriptionUI called")
        featuresContainer.isHidden = true
        termsLabel.isHidden = true
        skipButton.isHidden = true

        let activeTitle = R.string.global.subscriptionActiveSubtitle()
        var subtitleText = activeTitle

        if let nextPayment = IAPManager.shared.nextPaymentDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateStr = formatter.string(from: nextPayment)
            let validUntil = R.string.global.subscriptionValidUntil()
            subtitleText += "\n\(validUntil): \(dateStr)"
        }

        subtitleLabel.text = subtitleText
        subtitleLabel.numberOfLines = 0

        actionButton.setTitle(R.string.global.subscriptionManage(), for: .normal)
        actionButton.isEnabled = true
        actionButton.backgroundColor = UIColor.Button.background
        actionButton.removeTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(manageSubscriptionAction), for: .touchUpInside)
    }

    @objc private func manageSubscriptionAction() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc private func updateUI() {
        updateProductUI()
    }

    // MARK: - Read-Only Mode

    func enableReadOnlyMode() {
        skipButton.isHidden = false
        skipButton.setTitle(R.string.global.subscriptionContinueReadOnly(), for: .normal)
        skipButton.addTarget(self, action: #selector(skipAction), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func skipAction() {
        if let onSkip = onSkip {
            onSkip()
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func purchaseAction() {
        guard let product = selectedProduct else {
            fetchProducts()
            return
        }

        RequestManager.shared.getSubscriptionInfo { [weak self] (subscription) in
            if subscription.proPlan {
                DispatchQueue.main.async {
                    self?.showAlert(nil, body: R.string.global.hasProPlan())
                }
                return
            }
            self?.purchaseProduct(product)
        }
    }

    private func purchaseProduct(_ product: SKProduct) {
        IAPManager.shared.verifySubscription { [weak self] receipt in
            guard let self = self else { return }

            if let receipt = receipt, receipt.hasActiveAutorenewSubscription {
                DispatchQueue.main.async {
                    self.showAlert(nil, body: R.string.global.hasProPlan())
                }
                return
            }

            IAPManager.shared.purchaseProduct(product) { [weak self] success, error in
                if success {
                    DispatchQueue.main.async {
                        if let onSuccess = self?.onSubscriptionSuccess {
                            onSuccess()
                            return
                        }

                        if self?.presentingViewController != nil {
                            self?.dismiss(animated: true)
                            return
                        }

                        self?.showAlert(
                            R.string.global.success(),
                            body: R.string.global.successPurchase()
                        )
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showAlert(
                            R.string.global.error(),
                            body: error ?? R.string.global.wentWrongTryAgain()
                        )
                    }
                }
            }
        }
    }

    @objc private func restoreAction() {
        IAPManager.shared.restorePurchases { [weak self] in
            IAPManager.shared.verifySubscription { (receipt) in
                guard let self = self else { return }
                guard let receipt = receipt else {
                    DispatchQueue.main.async {
                        self.showAlert(
                            R.string.global.error(),
                            body: R.string.global.wentWrongTryAgain())
                    }
                    return
                }

                if receipt.hasSubscriptionPurchases {
                    guard let originTransactionId = receipt.lastAutorenewOriginTransactionId else {
                        return
                    }
                    RequestManager.shared.isSubscriptionPurchaseLinkedToAccount(originTransactionId) { (status) in
                        if status == .linkedCurrent || status == .notLinked {
                            IAPManager.shared.updateSubscriptionInfo(receipt)
                            DispatchQueue.main.async {
                                if let onSuccess = self.onSubscriptionSuccess {
                                    onSuccess()
                                    return
                                }

                                if self.presentingViewController != nil {
                                    self.dismiss(animated: true)
                                    return
                                }

                                self.showAlert(R.string.global.success(), body: R.string.global.purchaseRestored())
                                self.updateUI()
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if let onSuccess = self.onSubscriptionSuccess {
                            onSuccess()
                            return
                        }

                        if self.presentingViewController != nil {
                            self.dismiss(animated: true)
                            return
                        }

                        self.showAlert(R.string.global.success(), body: R.string.global.purchaseRestored())
                    }
                }
            }
        }
    }

    @objc private func openTerms() {
        guard let url = URL(string: Links.termsOfService) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }

    @objc private func openPrivacy() {
        guard let url = URL(string: Links.privacyPolicy) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}

// MARK: - Factory
extension SubscriptionController {
    static func makeDefault() -> SubscriptionController {
        return SubscriptionController("")
    }

    static func makeReached() -> SubscriptionController {
        return SubscriptionController("")
    }

    static func makeExpired() -> SubscriptionController {
        return SubscriptionController("")
    }

    static func makeNeedSub() -> SubscriptionController {
        return SubscriptionController("")
    }
}
