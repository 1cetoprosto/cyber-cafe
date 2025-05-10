//
//  SubscriptionController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import UIKit
import StoreKit
import SwiftyStoreKit

extension SubscriptionController {
    
    static func makeDefault() -> SubscriptionController {
        return SubscriptionController(R.string.global.subscriptionDefaultHeader())
    }
    
    static func makeReached() -> SubscriptionController {
        return SubscriptionController(R.string.global.subscriptionReachedHeader())
    }
    
    static func makeExpired() -> SubscriptionController {
        return SubscriptionController(R.string.global.subscriptionExpiredHeader())
    }
    
    static func makeNeedSub() -> SubscriptionController {
        return SubscriptionController(R.string.global.subscriptionNeedSubHeader())
    }
}

class SubscriptionController: UITableViewController {
    
    private enum Sections: Int, CaseIterable {
        case current
        case options
        case footer
    }
    
    private lazy var headerView: SubscriptionReuseView = {
        let view = SubscriptionReuseView()
        view.text = headerText
        view.textColor = .black
        view.font = .systemFont(ofSize: 17, weight: .medium)
        return view
    }()
    
    private let headerText: String?
    private var products = [SKProduct]()
    
    init(_ text: String) {
        headerText = text
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.subscription()
        
        tableView.register(baseCell: SubscriptionCell.self)
        tableView.separatorStyle = .none
        
        tableView.tableHeaderView = headerView
        
        IAPManager.shared.getProducts {[weak self] (products) in
            self?.products = products ?? []
            self?.tableView.reloadData()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .subscriptionInfoReload, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resizeTable()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeTable()
    }
    
    private func resizeTable() {
        if let headerView = tableView.tableHeaderView, let fitView = tableView.sizeToFitComponent(headerView) {
            tableView.tableHeaderView = fitView
        }
        if let footerView = tableView.tableFooterView, let fitView = tableView.sizeToFitComponent(footerView) {
            tableView.tableFooterView = fitView
        }
    }
    
    @objc private func checkPurchases() {
        RequestManager.shared.getSubscriptionInfo {[weak self] (subscription) in
            guard let self = self else { return }
            if subscription.provider == .android {
                self.showAlert(nil, body: R.string.global.manageSubFromAndroid())
                return
            }
            
            IAPManager.shared.restorePurchases {
                IAPManager.shared.verifySubscription { (receipt) in
                    guard let receipt = receipt else {
                        self.showAlert(R.string.global.error(),
                                       body: R.string.global.wentWrongTryAgain())
                        return
                    }
                    if receipt.hasSubscriptionPurchases {
                        guard let originTransactionId = receipt.lastAutorenewOriginTransactionId else {
                            fatalError("User has subscription but doesn't have origin transaction ID")
                        }
                        RequestManager.shared.isSubscriptionPurchaseLinkedToAccount(originTransactionId) { (status) in
                            guard let status = status else {
                                self.showAlert(R.string.global.error(),
                                               body: R.string.global.wentWrongTryAgain())
                                return
                            }
                            switch status {
                                case .notLinked, .linkedCurrent:
                                    IAPManager.shared.updateSubscriptionInfo(receipt)
                                case .linkedAnother:
                                    break
                            }
                            self.showAlert(R.string.global.success(),
                                           body: R.string.global.purchaseRestored())
                        }
                    } else {
                        self.showAlert(R.string.global.success(),
                                       body: R.string.global.purchaseRestored())
                    }
                }
                self.reloadData()
            }
        }
    }
    
    @objc private func reloadData() {
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section)! {
            case .current:
                return 2
            case .options:
                return products.count
            case .footer:
                return 5
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section)! {
            case .options:
                return R.string.global.subscriptionOptions()
            case .current:
                return R.string.global.currentSubscription()
            case .footer:
                return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Sections(rawValue: indexPath.section)! {
            case .current:
                if indexPath.item == 1 {
                    let cell = UITableViewCell()
                    let restoreButton = UIButton()
                    restoreButton.setTitle(R.string.global.restorePurchases(), for: .normal)
                    restoreButton.setTitleColor(.systemBlue, for: .normal)
                    restoreButton.setTitleColor(UIColor.systemBlue.alpha(0.5), for: .highlighted)
                    restoreButton.titleLabel?.font = .systemFont(ofSize: 14)
                    restoreButton.height(30)
                    restoreButton.addTarget(self, action: #selector(checkPurchases), for: .touchUpInside)
                    cell.contentView.addSubview(restoreButton)
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    restoreButton.centerXToSuperview()
                    restoreButton.topToSuperview(offset: 10)
                    restoreButton.bottomToSuperview()
                    cell.selectionStyle = .none
                    return cell
                }
                if let product = products.first(where: { $0.productIdentifier == IAPManager.shared.currentSubscription.productId }) {
                    let cell = tableView.dequeueBaseCell(SubscriptionCell.self, for: indexPath)
                    cell.setup(product)
                    cell.selectionStyle = .none
                    return cell
                } else {
                    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                    cell.textLabel?.numberOfLines = 0
                    cell.textLabel?.font = .systemFont(ofSize: 12)
                    if #available(iOS 13.0, *) {
                        cell.textLabel?.textColor = .secondaryLabel
                    } else {
                        cell.textLabel?.textColor = .lightText
                    }
                    cell.textLabel?.text = "\(R.string.global.currentSubscription()): \(IAPManager.shared.currentSubscription.name)"
                    cell.selectionStyle = .none
                    return cell
                }
            case .options:
                let cell = tableView.dequeueBaseCell(SubscriptionCell.self, for: indexPath)
                let product = products[indexPath.row]
                cell.setup(product)
                return cell
            case .footer:
                switch indexPath.item {
                    case 0:
                        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                        cell.backgroundColor = .clear
                        cell.textLabel?.textColor = .lightGray
                        cell.textLabel?.font = .systemFont(ofSize: 12, weight: .light)
                        cell.textLabel?.text = R.string.global.subscriptionFooter1()
                        cell.textLabel?.numberOfLines = 0
                        cell.selectionStyle = .none
                        return cell
                    case 1:
                        let cell = UITableViewCell()
                        let restoreButton = UIButton()
                        restoreButton.setTitle(R.string.global.manageSubscriptions(), for: .normal)
                        restoreButton.setTitleColor(.systemBlue, for: .normal)
                        restoreButton.setTitleColor(UIColor.systemBlue.alpha(0.5), for: .highlighted)
                        restoreButton.titleLabel?.font = .systemFont(ofSize: 12)
                        restoreButton.addTarget(self, action: #selector(openManageSubscriptions), for: .touchUpInside)
                        cell.contentView.addSubview(restoreButton)
                        cell.backgroundColor = .clear
                        cell.contentView.backgroundColor = .clear
                        restoreButton.leftToSuperview(offset: 20)
                        restoreButton.verticalToSuperview()
                        cell.selectionStyle = .none
                        return cell
                    case 2:
                        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                        cell.backgroundColor = .clear
                        cell.textLabel?.textColor = .lightGray
                        cell.textLabel?.font = .systemFont(ofSize: 12, weight: .light)
                        cell.textLabel?.text = R.string.global.subscriptionFooter2()
                        cell.textLabel?.numberOfLines = 0
                        cell.selectionStyle = .none
                        return cell
                    case 3:
                        let cell = UITableViewCell()
                        let restoreButton = UIButton()
                        restoreButton.setTitle("Terms Of Use", for: .normal)
                        restoreButton.setTitleColor(.systemBlue, for: .normal)
                        restoreButton.setTitleColor(UIColor.systemBlue.alpha(0.5), for: .highlighted)
                        restoreButton.titleLabel?.font = .systemFont(ofSize: 12)
                        restoreButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)
                        cell.contentView.addSubview(restoreButton)
                        cell.backgroundColor = .clear
                        cell.contentView.backgroundColor = .clear
                        restoreButton.centerXToSuperview()
                        restoreButton.verticalToSuperview()
                        cell.selectionStyle = .none
                        return cell
                    case 4:
                        let cell = UITableViewCell()
                        let restoreButton = UIButton()
                        restoreButton.setTitle("Privacy Policy", for: .normal)
                        restoreButton.setTitleColor(.systemBlue, for: .normal)
                        restoreButton.setTitleColor(UIColor.systemBlue.alpha(0.5), for: .highlighted)
                        restoreButton.titleLabel?.font = .systemFont(ofSize: 12)
                        restoreButton.addTarget(self, action: #selector(openPrivacy), for: .touchUpInside)
                        cell.contentView.addSubview(restoreButton)
                        cell.backgroundColor = .clear
                        cell.contentView.backgroundColor = .clear
                        restoreButton.centerXToSuperview()
                        restoreButton.verticalToSuperview()
                        cell.selectionStyle = .none
                        return cell
                    default:
                        fatalError()
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section != Sections.options.rawValue { return }
        let product = products[indexPath.item]
        RequestManager.shared.getSubscriptionInfo {[weak self] (subscription) in
            if subscription.premiumPlan {
                self?.showAlert(nil, body: R.string.global.hasPremiumPlan())
                return
            }
            if subscription.provider == .android {
                self?.showAlert(nil, body: R.string.global.manageSubFromAndroid())
                return
            }
            IAPManager.shared.restorePurchases {
                IAPManager.shared.verifySubscription { (receipt) in
                    guard let self = self else { return }
                    guard let receipt = receipt else {
                        self.showAlert(R.string.global.error(),
                                       body: R.string.global.wentWrongTryAgain())
                        return
                    }
                    if receipt.hasSubscriptionPurchases {
                        guard let originTransactionId = receipt.lastAutorenewOriginTransactionId else {
                            fatalError("User has subscription but doesn't have origin transaction ID")
                        }
                        RequestManager.shared.isSubscriptionPurchaseLinkedToAccount(originTransactionId) { (status) in
                            guard let status = status else {
                                self.showAlert(R.string.global.error(),
                                               body: R.string.global.wentWrongTryAgain())
                                return
                            }
                            switch status {
                                case .notLinked:
                                    IAPManager.shared.updateSubscriptionInfo(receipt)
                                    self.purchaseProduct(product)
                                case .linkedCurrent:
                                    IAPManager.shared.updateSubscriptionInfo(receipt)
                                    self.purchaseProduct(product)
                                case .linkedAnother:
                                    self.showAlert(R.string.global.error(),
                                                   body: R.string.global.appleIDReserved())
                                    return
                            }
                        }
                    } else {
                        if subscription.hasIOSSub {
                            self.showAlert(R.string.global.error(),
                                           body: R.string.global.labReserved())
                        } else {
                            self.purchaseProduct(product)
                        }
                    }
                }
            }
        }
    }
    
    private func purchaseProduct(_ product: SKProduct) {
        IAPManager.shared.purchaseProduct(product) {[weak self] success, error in
            if success {
                self?.showAlert(R.string.global.success(),
                                body: R.string.global.successPurchase())
            } else {
                self?.showAlert(R.string.global.error(),
                                body: error ?? R.string.global.wentWrongTryAgain())
            }
        }
    }
    
    private func showError() {
        showAlert(R.string.global.error(),
                  body: R.string.global.wentWrongTryAgain())
    }
    
    @objc private func openManageSubscriptions() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url, options: [:])
    }
    
    @objc private func openTerms() {
        guard let url = URL(string: "https://dtlabonline.blogspot.com/2021/01/terms-conditions-by-downloading-or.html") else { return }
        UIApplication.shared.open(url, options: [:])
    }
    @objc private func openPrivacy() {
        guard let url = URL(string: "https://dtlabonline.blogspot.com/2021/01/blog-post_9.html?m=1") else { return }
        UIApplication.shared.open(url, options: [:])
    }
}

