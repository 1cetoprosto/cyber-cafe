//
//  SettingListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import FirebaseAuth
import MessageUI
import RealmSwift
import SVProgressHUD
import UIKit
import SafariServices

struct Section {
    let title: String
    let footer: String?
    let option: [SettingsOptionType]
}

enum SettingsOptionType {
    case staticCell(model: SettingsStaticOption)
    case switchCell(model: SettingsSwitchOption)
    case dataCell(model: SettingsDataOption)
}

struct SettingsSwitchOption {
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let isOn: Bool
    let handler: ((Bool) -> Void)
}

struct SettingsStaticOption {
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let handler: (() -> Void)
}

struct SettingsDataOption {
    let title: String
    let icon: UIImage?
    let iconBackgroundColor: UIColor
    let data: String
    let handler: ((_ dataLabel: UILabel) -> Void)
}

class SettingListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    MFMailComposeViewControllerDelegate, Loggable
{

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            SettingsStaticTableViewCell.self,
            forCellReuseIdentifier: SettingsStaticTableViewCell.identifier)
        tableView.register(
            SettingsSwitchTableViewCell.self,
            forCellReuseIdentifier: SettingsSwitchTableViewCell.identifier)
        tableView.register(
            SettingsDataTableViewCell.self,
            forCellReuseIdentifier: SettingsDataTableViewCell.identifier)

        return tableView
    }()

    var models = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = R.string.global.menuSettings()
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView.delegate = self
        tableView.dataSource = self

        setConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configure()
        tableView.reloadData()
    }

    private func presentOrderModeSelection(
        currentMode: OrderEntryMode,
        completion: @escaping (OrderEntryMode) -> Void
    ) {
        PopupFactory.showOrderModePopup {
            completion(.perOrder)
        } selectOpenTab: {
            completion(.openTab)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OnboardingManager.shared.startIfNeeded(for: .settingsPriceList, on: self)
        OnboardingManager.shared.startIfNeeded(for: .settingsTypes, on: self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Handle system theme changes only if user has selected system appearance
        if Theme.currentSelection.appearance == .system {
            Theme.followSystemTheme()

            // Update UI colors
            view.backgroundColor = UIColor.Main.background
            tableView.backgroundColor = UIColor.Main.background
            tableView.reloadData()
        }
    }

    func configure() {
        models.removeAll()

        // 1. Establishment
        // TODO: Profile, Subscription, Staff
        // let establishmentOptions = [SettingsOptionType]()
        // models.append(Section(title: R.string.global.settingsSectionEstablishment(), footer: nil, option: establishmentOptions))

        // 2. Menu & Inventory
        let menuOptions: [SettingsOptionType] = [
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.priceList(),
                    icon: UIImage(systemName: SystemImages.cupAndSaucerFill),
                    iconBackgroundColor: .systemBrown
                ) {
                    self.navigationController?.pushViewController(
                        ProductListViewController(), animated: true)
                }),
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.ingredients(),
                    icon: UIImage(systemName: "cart"),
                    iconBackgroundColor: .systemOrange
                ) {
                    self.navigationController?.pushViewController(
                        IngredientListViewController(), animated: true)
                }),
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.productCategories(),
                    icon: UIImage(systemName: "square.grid.2x2"),
                    iconBackgroundColor: .systemPurple
                ) {
                    self.navigationController?.pushViewController(
                        ProductCategoriesListViewController(), animated: true)
                }),
        ]
        models.append(
            Section(
                title: R.string.global.settingsSectionMenuInventory(), footer: nil,
                option: menuOptions)
        )

        // 3. Orders
        let currentMode = SettingsManager.shared.loadOrderEntryMode()
        let orderModeTitle: String
        switch currentMode {
        case .perOrder:
            orderModeTitle = R.string.global.orderModePerOrder()
        case .openTab:
            orderModeTitle = R.string.global.orderModeOpenTab()
        }

        let orderOptions: [SettingsOptionType] = [
            .dataCell(
                model: SettingsDataOption(
                    title: R.string.global.orderEntryModeTitle(),
                    icon: UIImage(systemName: "list.bullet"),
                    iconBackgroundColor: .systemTeal,
                    data: orderModeTitle
                ) { dataLabel in
                    self.presentOrderModeSelection(currentMode: currentMode) { newMode in
                        SettingsManager.shared.saveOrderEntryMode(newMode)
                        switch newMode {
                        case .perOrder:
                            dataLabel.text = R.string.global.orderModePerOrder()
                        case .openTab:
                            dataLabel.text = R.string.global.orderModeOpenTab()
                        }
                    }
                }),
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.receiptTypes(),
                    icon: UIImage(systemName: SystemImages.banknoteFill),
                    iconBackgroundColor: .systemGreen
                ) {
                    self.navigationController?.pushViewController(
                        TypesListViewController(), animated: true)
                }),
        ]
        models.append(
            Section(
                title: R.string.global.settingsSectionOrders(),
                footer: NSLocalizedString("typeDescription", tableName: "Global", comment: ""),
                option: orderOptions)
        )

        // 4. Appearance
        let appearanceOptions: [SettingsOptionType] = [
            .dataCell(
                model: SettingsDataOption(
                    title: R.string.global.theme(),
                    icon: UIImage(systemName: SystemImages.sunMax),
                    iconBackgroundColor: .systemBlue,
                    data: SettingsManager.shared.loadTheme()
                ) { dataLabel in
                    self.alertTheme(label: dataLabel) { option in
                        Theme.apply(option: option)
                        SettingsManager.shared.saveTheme(option.displayName)
                        dataLabel.text = option.displayName
                        self.updateInterfaceForNewTheme()
                    }
                })
        ]
        models.append(
            Section(
                title: R.string.global.settingsSectionAppearance(), footer: nil,
                option: appearanceOptions)
        )

        // 5. App Info
        var appInfoOptions: [SettingsOptionType] = [
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.restartOnboarding(),
                    icon: UIImage(systemName: SystemImages.gearshape),
                    iconBackgroundColor: .systemMint
                ) {
                    OnboardingManager.shared.resetForCurrentAppVersion()
                    let alert = UIAlertController(
                        title: R.string.global.onboardingResetTitle(),
                        message: R.string.global.onboardingResetMessage(),
                        preferredStyle: .alert)
                    alert.addAction(
                        UIAlertAction(title: R.string.global.actionOk(), style: .default) { _ in
                            OnboardingManager.shared.startIfNeeded(
                                for: .settingsPriceList, on: self)
                            OnboardingManager.shared.startIfNeeded(for: .settingsTypes, on: self)
                        })
                    self.present(alert, animated: true)
                }),
            .staticCell(
                model: SettingsStaticOption(
                    title: NSLocalizedString("privacyPolicy", tableName: "Global", comment: ""),
                    icon: UIImage(systemName: "hand.raised.fill"),
                    iconBackgroundColor: .systemGray
                ) { [weak self] in
                    guard let self = self else { return }
                    self.openSafari(url: self.getLegalUrl(type: .privacy))
                }),
            .staticCell(
                model: SettingsStaticOption(
                    title: NSLocalizedString("termsOfService", tableName: "Global", comment: ""),
                    icon: UIImage(systemName: "doc.text.fill"),
                    iconBackgroundColor: .systemGray
                ) { [weak self] in
                    guard let self = self else { return }
                    self.openSafari(url: self.getLegalUrl(type: .terms))
                }),
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.writeToDeveloper(),
                    icon: UIImage(systemName: SystemImages.envelopeFill),
                    iconBackgroundColor: .systemOrange
                ) {
                    self.presentFeedbackEmail()
                }),
        ]

        if DemoDataManager.shared.isDemoDataPresent {
            appInfoOptions.append(
                .staticCell(
                    model: SettingsStaticOption(
                        title: R.string.global.deleteDemoData(),
                        icon: UIImage(systemName: "trash"),
                        iconBackgroundColor: .systemRed
                    ) {
                        self.confirmDeleteDemoData()
                    }
                )
            )
        }

        models.append(
            Section(
                title: R.string.global.settingsSectionAppInfo(), footer: nil, option: appInfoOptions
            )
        )

        #if DEBUG
            let devOptions: [SettingsOptionType] = [
                .staticCell(
                    model: SettingsStaticOption(
                        title: R.string.global.seedTestData(),
                        icon: UIImage(systemName: SystemImages.gearshape),
                        iconBackgroundColor: .systemPurple
                    ) {
                        let alert = UIAlertController(
                            title: R.string.global.seedTestData(),
                            message: R.string.global.enterNumberOfDays(),
                            preferredStyle: .alert
                        )
                        alert.addTextField { tf in
                            tf.keyboardType = .numberPad
                            tf.text = "14"
                        }
                        alert.addAction(
                            UIAlertAction(title: R.string.global.cancel(), style: .cancel))
                        alert.addAction(
                            UIAlertAction(title: R.string.global.seedAction(), style: .default) {
                                _ in
                                let daysText = alert.textFields?.first?.text ?? "14"
                                let days = Int(daysText) ?? 14
                                SVProgressHUD.show(withStatus: R.string.global.seedingData())
                                Task {
                                    await DomainDatabaseService.shared.seedTestData(forDays: days)
                                    await MainActor.run {
                                        SVProgressHUD.dismiss()
                                        SVProgressHUD.showSuccess(withStatus: "Done")
                                        self.tableView.reloadData()
                                    }
                                }
                            })
                        self.present(alert, animated: true)
                    })
            ]

            models.append(
                Section(title: R.string.global.developer(), footer: nil, option: devOptions))
        #endif

        // Add Logout button at the end
        let logout = SettingsOptionType.staticCell(
            model: SettingsStaticOption(
                title: R.string.global.logout(),
                icon: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
                iconBackgroundColor: .systemRed
            ) { [weak self] in
                self?.handleUserLogOut()
            }
        )
        models.append(Section(title: R.string.global.account(), footer: nil, option: [logout]))
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section = models[section]
        return section.footer
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].option.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section].option[indexPath.row]

        switch model.self {
        case .staticCell(let model):
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: SettingsStaticTableViewCell.identifier,
                    for: indexPath) as? SettingsStaticTableViewCell
            else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            if model.title == R.string.global.priceList() {
                cell.accessibilityIdentifier = "priceListCell"
            } else if model.title == R.string.global.receiptTypes() {
                cell.accessibilityIdentifier = "typesCell"
            }
            return cell
        case .switchCell(let model):
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: SettingsSwitchTableViewCell.identifier,
                    for: indexPath) as? SettingsSwitchTableViewCell
            else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .dataCell(let model):
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: SettingsDataTableViewCell.identifier,
                    for: indexPath) as? SettingsDataTableViewCell
            else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let type = models[indexPath.section].option[indexPath.row]

        switch type.self {
        case .staticCell(let model):
            model.handler()
        case .switchCell(_):
            break
        case .dataCell(let model):
            let cell = tableView.cellForRow(at: indexPath) as! SettingsDataTableViewCell
            model.handler(cell.dataLabel)
        }
    }

    func tableView(
        _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
    ) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Typography.footnote
        header.textLabel?.textColor = UIColor.Main.text
        if #available(iOS 11.0, *) { header.textLabel?.adjustsFontForContentSizeCategory = true }
    }

    func switchToDarkTheme(isOn: Bool) {
        logger.debug("Tap to switchDarkTheme isOn: \(isOn)")
    }

    func updateInterfaceForNewTheme() {
        // Update the UI after changing the theme
        configure()
        tableView.reloadData()
        self.restartApp()
    }

    private func restartApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            return
        }

        // Ensure the bundle is updated for the new language
        UserDefaults.standard.synchronize()

        let rootViewController = MainTabBarController()

        // Use animation for a ‘restart’
        UIView.transition(
            with: window, duration: 0.5, options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = rootViewController
            })
    }

    private func handleUserLogOut(shouldReload: Bool = true, completion: (() -> Void)? = nil) {
        UserSession.logOut()

        DispatchQueue.main.async {
            let signInController = SignInController()
            let navigationController = UINavigationController(rootViewController: signInController)
            navigationController.setNavigationBarHidden(true, animated: false)
            SceneDelegate.shared.set(root: navigationController)

            completion?()
        }
    }

    func authenticateUser(completion: @escaping (Bool) -> Void) {
        if Auth.auth().currentUser == nil {
            // User is not authenticated, present the sign-in screen
            let signInController = SignInController()
            signInController.completionHandler = { success in
                DispatchQueue.main.async {
                    if success {
                        completion(success)
                    } else {
                        self.showErrorAlert(
                            title: R.string.global.authenticationFailedTitle(),
                            message: R.string.global.authenticationFailedMessage()
                        )
                        completion(false)
                    }
                }
            }
            let navigationController = UINavigationController(rootViewController: signInController)
            navigationController.setNavigationBarHidden(true, animated: false)
            self.present(navigationController, animated: true, completion: nil)
        } else {
            // User is already authenticated
            completion(true)
        }
    }

    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: R.string.global.actionOk(), style: .default))
        present(alert, animated: true)
    }

    // MARK: - Feedback Email
    private func presentFeedbackEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            showErrorAlert(
                title: R.string.global.mailNotAvailableTitle(),
                message: R.string.global.mailNotAvailableMessage()
            )
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([supportEmail])
        mailComposer.setSubject(R.string.global.feedbackEmailSubject())

        // Get app version, device model, and OS version
        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? DefaultValues.unknownVersion
        let deviceModel = UIDevice.current.localizedModel
        let osVersion = UIDevice.current.systemVersion

        // Get user information
        let userId = UserSession.current.userId ?? DefaultValues.unknownUser
        let userEmail = UserSession.current.userEmail ?? DefaultValues.unknownUser
        let userRole = UserSession.current.role?.name ?? DefaultValues.unknownUser

        mailComposer.setMessageBody(
            R.string.global.feedbackEmailBody(
                appVersion, deviceModel, osVersion, userId, userEmail, userRole), isHTML: false)

        present(mailComposer, animated: true)
    }

    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(
        _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            switch result {
            case .sent:
                self?.showSuccessAlert()
            case .failed:
                self?.showErrorAlert(
                    title: R.string.global.sendFailedTitle(),
                    message: R.string.global.sendFailedMessage()
                )
            case .cancelled, .saved:
                break
            @unknown default:
                break
            }
        }
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: R.string.global.feedbackSuccessTitle(),
            message: R.string.global.feedbackSuccessMessage(),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: R.string.global.okButton(),
                style: .default
            ))
        present(alert, animated: true)
    }

    private func confirmDeleteDemoData() {
        let alert = UIAlertController(
            title: R.string.global.deleteDemoDataTitle(),
            message: R.string.global.deleteDemoDataMessage(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel))
        alert.addAction(
            UIAlertAction(title: R.string.global.delete(), style: .destructive) { _ in
                SVProgressHUD.show(
                    withStatus: R.string.global.deleting())
                DemoDataManager.shared.deleteDemoData { success in
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        if success {
                            self.configure()
                            self.tableView.reloadData()
                            SVProgressHUD.showSuccess(withStatus: R.string.global.actionDone())
                        } else {
                            SVProgressHUD.showError(withStatus: R.string.global.error())
                        }
                    }
                }
            })
        present(alert, animated: true)
    }

    // MARK: - Safari
    private func openSafari(url: String) {
        guard let url = URL(string: url) else { return }
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        present(safariVC, animated: true)
    }

    // MARK: - Legal URLs
    private enum LegalDocType {
        case privacy
        case terms
    }

    private func getLegalUrl(type: LegalDocType) -> String {
        // Check if the current language is Ukrainian
        let isUkrainian = Locale.current.languageCode == "uk"

        switch type {
        case .privacy:
            return isUkrainian
                ? "https://leokvit.notion.site/313f9211d4378065b441d8876d169bec?source=copy_link" // TODO: Replace with actual UA link
                : "https://leokvit.notion.site/Privacy-Policy-313f9211d437808aaf71cd2390e4671d?source=copy_link"
        case .terms:
            return isUkrainian
                ? "https://leokvit.notion.site/Terms-of-Service-313f9211d43780458359c1e9e7bf0076?source=copy_link" // TODO: Replace with actual UA link
                : "https://leokvit.notion.site/Terms-of-Service-313f9211d4378018b630fe6d2bfbbe09?source=copy_link"
        }
    }
}

// MARK: - Constraints
extension SettingListViewController {
    func setConstraints() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
    }
}
