//
//  SubscriptionBannerView.swift
//  TrackMyCafe
//
//  Created by Assistant on 27.02.2026.
//

import StoreKit
import UIKit
import TinyConstraints

protocol SubscriptionBannerViewDelegate: AnyObject {
    func didTapTryFree()
    func didTapPurchase(product: SKProduct)
}

final class SubscriptionBannerView: UIView {

    weak var delegate: SubscriptionBannerViewDelegate?
    var onInfoLoaded: (() -> Void)?
    private var product: SKProduct?

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        // Use cell background color to match other list items
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
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
        label.text = R.string.global.subscriptionBannerTitle()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        // Use system semantic color for text
        label.textColor = UIColor.Main.text
        return label
    }()

    private let proTagLabel: UILabel = {
        let label = UILabel()
        label.text = "PRO"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemOrange
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.global.subscriptionBannerDescription()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        // Use system semantic color for secondary text
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 3 // Explicitly set number of lines to force height calculation
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.subscriptionBannerAction(), for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.5
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    private let termsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        fetchProductInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        addSubview(containerView)

        containerView.edgesToSuperview(insets: .init(top: 10, left: 16, bottom: 10, right: 16))

        // Header Stack (Icon + Title + ProTag)
        let titleStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, proTagLabel])
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center

        iconImageView.size(CGSize(width: 40, height: 40))
        proTagLabel.size(CGSize(width: 36, height: 20))

        containerView.addSubview(titleStack)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(actionButton)
        containerView.addSubview(termsLabel)

        titleStack.topToSuperview(offset: 20)
        titleStack.centerXToSuperview()

        descriptionLabel.topToBottom(of: titleStack, offset: 12)
        descriptionLabel.leadingToSuperview(offset: 16)
        descriptionLabel.trailingToSuperview(offset: 16)

        // Force minimum height for 3 lines of text (approx 60pt)
        descriptionLabel.height(min: 60)

        actionButton.topToBottom(of: descriptionLabel, offset: 20)
        actionButton.leadingToSuperview(offset: 16)
        actionButton.trailingToSuperview(offset: 16)
        actionButton.height(44)

        termsLabel.topToBottom(of: actionButton, offset: 8)
        termsLabel.leadingToSuperview(offset: 16)
        termsLabel.trailingToSuperview(offset: 16)

        // This is the key constraint that pushes the container bottom down
        termsLabel.bottomToSuperview(offset: -16)
    }

    // MARK: - Logic

    private func fetchProductInfo() {
        actionButton.isEnabled = false
        actionButton.setTitle(R.string.global.loading(), for: .normal)

        IAPManager.shared.getProducts { [weak self] products in
            guard let self = self else { return }

            guard let products = products, !products.isEmpty else {
                DispatchQueue.main.async {
                    self.actionButton.setTitle(R.string.global.activatePro(), for: .normal)
                    self.actionButton.isEnabled = true
                }
                return
            }

            self.product = SubscriptionPresenter.shared.findBestProduct(in: products)
            guard let product = self.product else { return }

            DispatchQueue.main.async {
                self.actionButton.isEnabled = true
                
                let displayInfo = SubscriptionPresenter.shared.getDisplayInfo(for: product)
                
                self.actionButton.setTitle(displayInfo.buttonTitle, for: .normal)
                self.termsLabel.text = displayInfo.termsText

                // Notify parent to update layout
                self.onInfoLoaded?()
            }
        }
    }

    // MARK: - Actions

    @objc private func actionButtonTapped() {
        if let product = product {
            delegate?.didTapPurchase(product: product)
        } else {
            delegate?.didTapTryFree()
        }
    }
}
