//
//  SubscriptionController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import SafariServices
import StoreKit
import SwiftyStoreKit
import TinyConstraints
import UIKit

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
        let label = AppLabel(style: .footnote)
        label.text = R.string.global.appName()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let proTagLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.text = "PRO"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.Button.background
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        return label
    }()

    private let headlineLabel: UILabel = {
        let label = AppLabel(style: .largeTitleBold)
        label.apply(.largeTitleBold)
        label.text = R.string.global.subscriptionPaywallHeadline()
        label.textColor = Theme.current.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.apply(.bodyMultiline)
        label.text = R.string.global.subscriptionSubtitle()
        label.textColor = Theme.current.secondaryText
        label.textAlignment = .center
        return label
    }()

    private let summaryCard: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.current.cellBackground
        view.applyCafeSoftCardStyle()
        return view
    }()

    private let summaryStackView = UIStackView()

    private let featuresContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.current.cellBackground
        view.applyCafeSoftCardStyle()
        return view
    }()

    private let featuresStackView = UIStackView()

    private lazy var actionButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.loading(), for: .normal)
        button.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        let title = R.string.global.subscriptionContinueReadOnly()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(skipAction), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private let termsLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let footerStackView = UIStackView()
    private weak var restorePurchasesButton: UIButton?

    private var canManageSubscription: Bool {
        // Pre-login paywall may still offer purchase; staff sessions cannot.
        if UserSession.current.isAuth {
            return UserSession.current.canManageSubscription
        }
        return true
    }

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
            let isPro = await IAPManager.shared.resolveProAccess()
            await MainActor.run {
                self.logger.debug("SubscriptionController refreshed isPro: \(isPro)")
                if isPro {
                    if let onSuccess = self.onSubscriptionSuccess {
                        onSuccess()
                        return
                    }
                    self.setupActiveSubscriptionUI()
                } else if self.canManageSubscription {
                    self.fetchProducts()
                } else {
                    self.setupStaffNeedsOwnerUI()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        summaryCard.updateCafeSoftCardShadowPath()
        featuresContainer.updateCafeSoftCardShadowPath()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = Theme.current.primaryBackground
        titleLabel.textColor = Theme.current.primaryText
        skipButton.setTitleColor(Theme.current.secondaryText, for: .normal)
        termsLabel.textColor = Theme.current.secondaryText

        title = ""

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(mainStackView)
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.alignment = .fill

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, proTagLabel])
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center

        proTagLabel.width(40)
        proTagLabel.height(24)

        let headerStack = UIStackView(arrangedSubviews: [
            headerImageView, titleStack, headlineLabel, subtitleLabel,
        ])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.setCustomSpacing(16, after: titleStack)
        headerStack.setCustomSpacing(6, after: headlineLabel)

        setupSummaryCard()
        setupFeatures()

        featuresContainer.addSubview(featuresStackView)
        featuresStackView.edgesToSuperview(insets: .init(top: 16, left: 16, bottom: 16, right: 16))

        setupFooterLinks()

        mainStackView.addArrangedSubview(headerStack)
        mainStackView.addArrangedSubview(summaryCard)
        mainStackView.addArrangedSubview(featuresContainer)
        mainStackView.addArrangedSubview(actionButton)
        mainStackView.addArrangedSubview(skipButton)
        mainStackView.addArrangedSubview(termsLabel)
        mainStackView.addArrangedSubview(footerStackView)

        mainStackView.setCustomSpacing(24, after: headerStack)
        mainStackView.setCustomSpacing(16, after: summaryCard)
        mainStackView.setCustomSpacing(24, after: featuresContainer)
        mainStackView.setCustomSpacing(10, after: actionButton)
        mainStackView.setCustomSpacing(10, after: skipButton)
    }

    private func setupSummaryCard() {
        let summary = CafeDemoMoneyScenario.resolve().formattedSummary()

        summaryStackView.axis = .vertical
        summaryStackView.spacing = 10
        summaryStackView.alignment = .fill

        let comparison = AppLabel(style: .bodyDemiBold)
        comparison.apply(.bodyDemiBold)
        comparison.text = summary.comparison
        comparison.textAlignment = .center
        comparison.textColor = Theme.current.secondaryText

        let leftoverCaption = AppLabel(style: .kpiTitle)
        leftoverCaption.apply(.kpiTitle)
        leftoverCaption.text = R.string.global.hubBigNetLabel()
        leftoverCaption.textAlignment = .center
        leftoverCaption.textColor = UIColor.Semantic.kpiLabel

        let leftoverValue = UILabel()
        leftoverValue.text = summary.left
        leftoverValue.font = .systemFont(ofSize: 36, weight: .bold)
        leftoverValue.textAlignment = .center
        leftoverValue.textColor = UIColor.Semantic.positive
        leftoverValue.adjustsFontSizeToFitWidth = true
        leftoverValue.minimumScaleFactor = 0.5

        let divider = UIView()
        divider.backgroundColor = UIColor.Semantic.cardStroke
        divider.height(1 / UIScreen.main.scale)

        summaryStackView.addArrangedSubview(comparison)
        summaryStackView.addArrangedSubview(leftoverCaption)
        summaryStackView.addArrangedSubview(leftoverValue)
        summaryStackView.addArrangedSubview(divider)
        summaryStackView.addArrangedSubview(
            makePaywallAmountRow(
                title: R.string.global.hubBigSalesLabel(),
                value: "+\(summary.sales)",
                color: UIColor.Semantic.positive
            )
        )
        summaryStackView.addArrangedSubview(
            makePaywallAmountRow(
                title: R.string.global.hubBigCostsLabel(),
                value: "−\(summary.costsTotal)",
                color: UIColor.Semantic.cost
            )
        )

        let afterCostsDivider = UIView()
        afterCostsDivider.backgroundColor = UIColor.Semantic.cardStroke
        afterCostsDivider.height(1 / UIScreen.main.scale)
        summaryStackView.addArrangedSubview(afterCostsDivider)

        summaryStackView.addArrangedSubview(
            makePaywallAmountRow(
                title: R.string.global.hubBigNetLabel(),
                value: summary.left,
                color: UIColor.Semantic.positive
            )
        )

        summaryStackView.setCustomSpacing(4, after: leftoverCaption)
        summaryStackView.setCustomSpacing(14, after: leftoverValue)
        summaryStackView.setCustomSpacing(12, after: divider)

        summaryCard.addSubview(summaryStackView)
        summaryStackView.edgesToSuperview(insets: .uniform(16))
    }

    private func makePaywallAmountRow(title: String, value: String, color: UIColor) -> UIView {
        let titleLabel = AppLabel(style: .body)
        titleLabel.apply(.body)
        titleLabel.text = title
        titleLabel.textColor = Theme.current.secondaryText

        let valueLabel = AppLabel(style: .bodyDemiBold)
        valueLabel.apply(.bodyDemiBold)
        valueLabel.text = value
        valueLabel.textAlignment = .right
        valueLabel.textColor = color
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 8
        return row
    }

    private func setupFeatures() {
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 14

        // Outcome-first: max 3 benefits (not a full feature catalog).
        let features = [
            R.string.global.subscriptionFeature1(),
            R.string.global.subscriptionFeature2(),
            R.string.global.subscriptionFeature3(),
        ]

        for feature in features {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center

            let iconContainer = UIView()
            iconContainer.backgroundColor = UIColor.Semantic.positiveFill
            iconContainer.layer.cornerRadius = 10
            iconContainer.clipsToBounds = true

            let icon = UIImageView(image: UIImage(systemName: "checkmark"))
            icon.tintColor = UIColor.Semantic.positive
            icon.contentMode = .scaleAspectFit

            iconContainer.addSubview(icon)
            icon.centerInSuperview()
            icon.width(10)
            icon.height(10)

            iconContainer.width(20)
            iconContainer.height(20)

            let label = AppLabel(style: .body)
            label.apply(.body)
            label.text = feature
            label.textColor = Theme.current.primaryText
            label.numberOfLines = 0

            row.addArrangedSubview(iconContainer)
            row.addArrangedSubview(label)
            featuresStackView.addArrangedSubview(row)
        }
    }

    private func setupFooterLinks() {
        footerStackView.axis = .vertical
        footerStackView.spacing = 8
        footerStackView.alignment = .center

        let restoreButton = createFooterButton(
            title: R.string.global.restorePurchases(), action: #selector(restoreAction))
        restorePurchasesButton = restoreButton

        let policyStack = UIStackView()
        policyStack.axis = .horizontal
        policyStack.spacing = 8

        let privacyButton = createFooterButton(
            title: R.string.global.privacyPolicy(), action: #selector(openPrivacy))
        let termsButton = createFooterButton(
            title: R.string.global.termsOfUse(), action: #selector(openTerms))
        let separator = createSeparator()

        policyStack.addArrangedSubview(privacyButton)
        policyStack.addArrangedSubview(separator)
        policyStack.addArrangedSubview(termsButton)

        footerStackView.addArrangedSubview(restoreButton)
        footerStackView.addArrangedSubview(policyStack)
    }

    private func createSeparator() -> UILabel {
        let label = AppLabel(style: .footnote)
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
    }

    // MARK: - Logic

    private func fetchProducts() {
        actionButton.isEnabled = false
        actionButton.setTitle(R.string.global.loading(), for: .normal)

        IAPManager.shared.getProducts { [weak self] (products) in
            guard let self = self else { return }

            guard let products = products, !products.isEmpty else {
                DispatchQueue.main.async {
                    self.actionButton.setTitle(
                        R.string.global.subscriptionBannerAction(), for: .normal)
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
                    guard let subscription = RequestManager.shared.subscription else {
                        return false
                    }
                    if subscription.nextPaymentDate != nil { return true }
                    if (subscription.transactionId ?? subscription.originTransactionId) != nil {
                        return true
                    }
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

        actionButton.setTitle(displayInfo.buttonTitle, for: .normal)
        termsLabel.text = displayInfo.termsText

        if IAPManager.shared.isProPlan == true {
            // First-run / gated flows pass onSubscriptionSuccess — leave instead of
            // showing the empty “Manage Subscription” status screen.
            if let onSuccess = onSubscriptionSuccess {
                onSuccess()
                return
            }
            setupActiveSubscriptionUI()
        } else {
            setupInactiveSubscriptionUI()
        }
    }

    private func setupInactiveSubscriptionUI() {
        headlineLabel.isHidden = false
        summaryCard.isHidden = false
        featuresContainer.isHidden = false
        termsLabel.isHidden = false
        restorePurchasesButton?.isHidden = false

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

    private func setupStaffNeedsOwnerUI() {
        headlineLabel.isHidden = false
        summaryCard.isHidden = true
        featuresContainer.isHidden = false
        termsLabel.isHidden = true
        skipButton.isHidden = true
        restorePurchasesButton?.isHidden = true

        subtitleLabel.text = R.string.global.subscriptionAskOwner()
        subtitleLabel.textColor = UIColor.Main.secondaryText
        subtitleLabel.numberOfLines = 0

        actionButton.setTitle(R.string.global.cancel(), for: .normal)
        actionButton.isEnabled = true
        actionButton.backgroundColor = UIColor.Button.background
        actionButton.removeTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        actionButton.removeTarget(
            self, action: #selector(manageSubscriptionAction), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(skipAction), for: .touchUpInside)
    }

    private func setupActiveSubscriptionUI() {
        logger.debug("setupActiveSubscriptionUI called")
        if let onSuccess = onSubscriptionSuccess {
            onSuccess()
            return
        }

        headlineLabel.isHidden = true
        summaryCard.isHidden = true
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

        if canManageSubscription {
            restorePurchasesButton?.isHidden = false
            actionButton.setTitle(R.string.global.subscriptionManage(), for: .normal)
            actionButton.isEnabled = true
            actionButton.backgroundColor = UIColor.Button.background
            actionButton.removeTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
            actionButton.removeTarget(self, action: #selector(skipAction), for: .touchUpInside)
            actionButton.addTarget(
                self, action: #selector(manageSubscriptionAction), for: .touchUpInside)
        } else {
            restorePurchasesButton?.isHidden = true
            actionButton.setTitle(R.string.global.cancel(), for: .normal)
            actionButton.isEnabled = true
            actionButton.backgroundColor = UIColor.Button.background
            actionButton.removeTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
            actionButton.removeTarget(
                self, action: #selector(manageSubscriptionAction), for: .touchUpInside)
            actionButton.addTarget(self, action: #selector(skipAction), for: .touchUpInside)
        }
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
        guard canManageSubscription else {
            showAlert(
                R.string.global.subscription(),
                body: R.string.global.subscriptionAskOwner()
            )
            return
        }

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
        guard canManageSubscription else {
            showAlert(
                R.string.global.subscription(),
                body: R.string.global.subscriptionAskOwner()
            )
            return
        }

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

                                self.showAlert(
                                    R.string.global.success(),
                                    body: R.string.global.purchaseRestored())
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

                        self.showAlert(
                            R.string.global.success(), body: R.string.global.purchaseRestored())
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
