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

class SubscriptionController: UIViewController {

    // MARK: - Properties
    private var products = [SKProduct]()
    private var selectedProduct: SKProduct?

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mainStackView = UIStackView()

    // Header
    private let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20 // Rounded corners like app icon
        imageView.clipsToBounds = true

        // Try to fetch App Icon from Bundle Info.plist
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            imageView.image = UIImage(named: lastIcon)
        }

        // Fallback to crown if AppIcon is not accessible
        if imageView.image == nil {
            imageView.image = UIImage(systemName: "crown.fill")
            imageView.tintColor = .systemOrange
        }
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "TrackMyCafe" // "PRO" will be a separate tag
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor.Main.text
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
        label.textColor = UIColor.Main.secondaryText // Using secondary text color (brown/gray)
        label.textAlignment = .center
        return label
    }()

    // Features
    private let featuresContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let featuresStackView = UIStackView()

    // Pricing Info
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

    // Action Button
    private lazy var actionButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.loading(), for: .normal)
        button.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        return button
    }()

    private let termsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // Footer
    private let footerStackView = UIStackView()

    // MARK: - Init

    // We keep this factory method for compatibility but ignore the header text as we use custom UI
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
        fetchProducts()

        NotificationCenter.default.addObserver(
            self, selector: #selector(updateUI), name: .subscriptionInfoReload, object: nil)
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = ""

        // ScrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Main Stack
        contentView.addSubview(mainStackView)
        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.alignment = .fill

        // Header
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

        // Features
        setupFeatures()

        // Add Features Stack to Container with Insets
        featuresContainer.addSubview(featuresStackView)
        featuresStackView.edgesToSuperview(insets: .init(top: 16, left: 16, bottom: 16, right: 16))

        // Footer Links
        setupFooterLinks()

        // Add to Main Stack
        mainStackView.addArrangedSubview(headerStack)
        mainStackView.addArrangedSubview(featuresContainer)

        // Pricing Section
        mainStackView.addArrangedSubview(trialBadge)
        // Price labels removed, info moved to button

        mainStackView.addArrangedSubview(actionButton)
        mainStackView.addArrangedSubview(termsLabel)
        mainStackView.addArrangedSubview(footerStackView)

        // Spacing
        mainStackView.setCustomSpacing(40, after: headerStack)
        mainStackView.setCustomSpacing(30, after: featuresContainer)

        // Adjust spacing around pricing info
        mainStackView.setCustomSpacing(8, after: trialBadge)

        mainStackView.setCustomSpacing(10, after: actionButton)
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

            // Custom checkmark icon (circle with check)
            let iconContainer = UIView()
            iconContainer.backgroundColor = .systemOrange
            iconContainer.layer.cornerRadius = 10 // 20x20 circle
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

            // Add separator if not last item
            if index < features.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3) // Standard separator color
                separator.height(0.5)
                featuresStackView.addArrangedSubview(separator)

                // Optional: add leading inset for separator to align with text
                // separator.leadingToSuperview(offset: 48)
                // But full width separator inside the card looks clean too
            }
        }
    }

    private func setupFooterLinks() {
        // Change to vertical stack for better readability
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

        mainStackView.edgesToSuperview(insets: .init(top: 20, left: 20, bottom: 40, right: 20))

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
                    self.actionButton.setTitle(R.string.global.activatePro(), for: .normal)
                    self.actionButton.isEnabled = true
                }
                return
            }

            self.products = products

            // Assuming we want to show the monthly subscription as primary or the one with trial
            // Logic: Pick the one that matches current subscription type or default to first
            // Usually we want to show the "Pro Monthly" or similar.

            // Let's try to find a monthly product first
            if let monthly = products.first(where: { $0.productIdentifier.contains("month") }) {
                self.selectedProduct = monthly
            } else {
                self.selectedProduct = products.first
            }

            self.updateProductUI()
        }
    }

    private func updateProductUI() {
        guard let product = selectedProduct else { return }

        actionButton.isEnabled = true

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let priceString = formatter.string(from: product.price) ?? "\(product.price)"

        // Check for Introductory Price (Trial)
        if let introPrice = product.introductoryPrice,
           introPrice.paymentMode == .freeTrial {

            // Trial Logic
            let days = introPrice.subscriptionPeriod.numberOfUnits
            let periodUnit = introPrice.subscriptionPeriod.unit
            var daysCount = 7 // Default

            if periodUnit == .day { daysCount = days }
            else if periodUnit == .week { daysCount = days * 7 }
            else if periodUnit == .month { daysCount = days * 30 }
            else if periodUnit == .year { daysCount = days * 365 }

            // Hide badge as the button text already contains "14 days free" info
            trialBadge.isHidden = true

            // Format: "14 днів безплатно"
            actionButton.setTitle(R.string.global.tryButtonTitle(daysCount), for: .normal)

            // Text below: "Потім 199 грн/міс. Автоматичне подовження."
            termsLabel.text = R.string.global.trialTermsText(priceString)

        } else {
            // Regular Price
            trialBadge.isHidden = true

            // Format: "Підписатися за 199 грн/міс"
            actionButton.setTitle(R.string.global.subscribeButtonTitle(priceString), for: .normal)

            // Text below: "Скасувати можна в будь-який час."
            termsLabel.text = R.string.global.noTrialTermsText()
        }

        // Update styling if user is already premium
        if IAPManager.shared.isPremiumPlan == true {
            actionButton.setTitle("Вже активовано", for: .normal)
            actionButton.isEnabled = false
            actionButton.backgroundColor = .systemGray
        }
    }

    @objc private func updateUI() {
        updateProductUI()
    }

    // MARK: - Actions

    @objc private func purchaseAction() {
        guard let product = selectedProduct else { return }

        // Existing Purchase Logic
        RequestManager.shared.getSubscriptionInfo { [weak self] (subscription) in
            if subscription.premiumPlan {
                self?.showAlert(nil, body: R.string.global.hasPremiumPlan())
                return
            }
            self?.purchaseProduct(product)
        }
    }

    private func purchaseProduct(_ product: SKProduct) {
        IAPManager.shared.purchaseProduct(product) { [weak self] success, error in
            if success {
                self?.showAlert(
                    R.string.global.success(),
                    body: R.string.global.successPurchase())
                self?.dismiss(animated: true)
            } else {
                self?.showAlert(
                    R.string.global.error(),
                    body: error ?? R.string.global.wentWrongTryAgain())
            }
        }
    }

    @objc private func restoreAction() {
        IAPManager.shared.restorePurchases { [weak self] in
            IAPManager.shared.verifySubscription { (receipt) in
                guard let self = self else { return }
                guard let receipt = receipt else {
                    self.showAlert(
                        R.string.global.error(),
                        body: R.string.global.wentWrongTryAgain())
                    return
                }

                if receipt.hasSubscriptionPurchases {
                     // Reuse existing logic from original controller
                    guard let originTransactionId = receipt.lastAutorenewOriginTransactionId else {
                        return
                    }
                    RequestManager.shared.isSubscriptionPurchaseLinkedToAccount(originTransactionId) { (status) in
                        if status == .linkedCurrent || status == .notLinked {
                            IAPManager.shared.updateSubscriptionInfo(receipt)
                            self.showAlert(R.string.global.success(), body: R.string.global.purchaseRestored())
                            self.updateUI()
                        }
                    }
                } else {
                    self.showAlert(R.string.global.success(), body: R.string.global.purchaseRestored())
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
         guard let url = URL(string: "https://leokvit.notion.site/Privacy-Policy-313f9211d4378065b441d8876d169bec?source=copy_link") else { return }
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
