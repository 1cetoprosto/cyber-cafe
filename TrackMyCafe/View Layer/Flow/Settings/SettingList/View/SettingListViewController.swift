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

struct Section {
    let title: String
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
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            SettingsStaticTableViewCell.self,
            forCellReuseIdentifier: SettingsStaticTableViewCell.identifier)
        tableView.register(
            SettingsSwitchTableViewCell.self,
            forCellReuseIdentifier: SettingsSwitchTableViewCell.identifier)
        tableView.register(
            SettingsDataTableViewCell.self, forCellReuseIdentifier: SettingsDataTableViewCell.identifier)

        return tableView
    }()

    var models = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = R.string.global.menuSettings()

        tableView.delegate = self
        tableView.dataSource = self

        setConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configure()
        tableView.reloadData()
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

        var options = [SettingsOptionType]()

        //    // Language settings
        //    options.append(
        //      .dataCell(
        //        model: SettingsDataOption(
        //          title: "Language",
        //          icon: UIImage(systemName: "globe"),
        //          iconBackgroundColor: .systemPink,
        //          data: SettingsManager.shared.loadLanguage()
        //        ) { dataLabel in
        //          self.alertLanguage(label: dataLabel) { language in
        //            SettingsManager.shared.setAppLanguage(language)
        //            dataLabel.text = language
        //            self.updateInterfaceForNewTheme()
        //          }
        //        }))

        // Theme settings
        options.append(
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
                }))

        options.append(
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
                            OnboardingManager.shared.startIfNeeded(for: .settingsPriceList, on: self)
                            OnboardingManager.shared.startIfNeeded(for: .settingsTypes, on: self)
                        })
                    self.present(alert, animated: true)
                }))

        // Feedback option
        options.append(
            .staticCell(
                model: SettingsStaticOption(
                    title: R.string.global.writeToDeveloper(),
                    icon: UIImage(systemName: SystemImages.envelopeFill),
                    iconBackgroundColor: .systemOrange
                ) {
                    self.presentFeedbackEmail()
                }))

        // // Subscription management
        // options.append(
        //   .staticCell(
        //     model: SettingsStaticOption(
        //       title: "Subscription",
        //       icon: UIImage(systemName: "creditcard.circle.fill"),
        //       iconBackgroundColor: .systemIndigo
        //     ) {
        //       // Open subscription management screen
        //       let controller = SubscriptionController.makeDefault()
        //       self.navigationController?.pushViewController(controller, animated: true)
        //     }))

        // // Exit option for online users
        // if UserSession.current.hasOnlineVersion {
        //   options.append(
        //     .dataCell(
        //       model: SettingsDataOption(
        //         title: "Exit",
        //         icon: UIImage(named: "exit"),
        //         iconBackgroundColor: .systemGreen,
        //         data: SettingsManager.shared.loadUserEmail()
        //       ) { dataLabel in
        //         UserSession.logOut()
        //       }))
        // }

        models.append(Section(title: R.string.global.general(), option: options))

        models.append(
            Section(
                title: R.string.global.income(),
                option: [
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
                            title: R.string.global.receiptTypes(),
                            icon: UIImage(systemName: SystemImages.banknoteFill),
                            iconBackgroundColor: .systemGreen
                        ) {
                            self.navigationController?.pushViewController(
                                TypesListViewController(), animated: true)
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
                    // .staticCell(
                    //   model: SettingsStaticOption(
                    //     title: "Staff",
                    //     icon: UIImage(systemName: "person.2.fill"),
                    //     iconBackgroundColor: .systemMint
                    //   ) {
                    //     self.navigationController?.pushViewController(
                    //       StaffCategoriesController(), animated: true)
                    //   }),

                ]))

        #if DEBUG
            #if targetEnvironment(simulator)
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
                            alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel))
                            alert.addAction(
                                UIAlertAction(title: R.string.global.seedAction(), style: .default) { _ in
                                    let daysText = alert.textFields?.first?.text ?? "14"
                                    let days = Int(daysText) ?? 14
                                    SVProgressHUD.show(withStatus: R.string.global.seedingData())
                                    Task {
                                        await DomainDatabaseService.shared.seedTestData(forDays: days)
                                        await SVProgressHUD.dismiss()
                                        self.tableView.reloadData()
                                    }
                                })
                            self.present(alert, animated: true)
                        })
                ]

                models.append(Section(title: R.string.global.developer(), option: devOptions))
            #endif
        #endif

        // models.append(
        //   Section(
        //     title: "Database",
        //     option: [
        //       .switchCell(
        //         model: SettingsSwitchOption(
        //           title: "Online",
        //           icon: UIImage(systemName: "icloud.fill"),
        //           iconBackgroundColor: .systemGreen,
        //           isOn: SettingsManager.shared.loadOnline()
        //         ) { isOn in
        //           //SettingsManager.shared.saveOnline(isOn)
        //           self.logger.notice("Online mode is \(isOn ? "On" : "Off")")
        //           self.toggleOfflineOnlineMode(isOn)
        //           //self.tableView.reloadData()
        //         })
        //     ]))
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = models[section]
        return section.title
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

    func toggleOfflineOnlineMode(_ isOn: Bool) {
        PopupFactory.showPopup(
            title: R.string.global.transferDataTitle(),
            description: R.string.global.transferDataDescription(),
            buttonTitle: R.string.global.transfer(),
            buttonAction: { [weak self] in
                SVProgressHUD.show(withStatus: R.string.global.transferingData())

                self?.authenticateUser { [weak self] success in
                    guard success else {
                        SVProgressHUD.dismiss()
                        return
                    }

                    if isOn {  //UserSession.current.hasOnlineVersion
                        DomainDatabaseService.shared.transferDataFromRealmToFIR {
                            self?.updateUIAfterDataTransfer(isOnline: isOn)
                        }
                    } else {
                        DomainDatabaseService.shared.transferDataFromFIRToRealm {
                            self?.handleUserLogOut {
                                self?.updateUIAfterDataTransfer(isOnline: isOn)
                            }
                        }
                    }
                }
            },
            startOverAction: { [weak self] in
                self?.logger.debug("StartOverAction triggered")
                self?.authenticateUser { [weak self] success in
                    guard success else {
                        self?.logger.error("Authentication failed")
                        SVProgressHUD.dismiss()
                        return
                    }
                    self?.logger.notice("Authentication successful")

                    UserSession.current.saveOnline(true)

                    DomainDatabaseService.shared.deleteActiveDatabaseData { _ in
                        self?.logger.notice("Data deleted from local database")
                        DispatchQueue.main.async {
                            self?.updateUIAfterDataTransfer(isOnline: isOn)
                        }
                    }
                }
            },
            cancelAction: { [weak self] in
                self?.authenticateUser { success in
                    guard success else {
                        SVProgressHUD.dismiss()
                        return
                    }

                    if !UserSession.current.hasOnlineVersion {
                        self?.handleUserLogOut {
                            self?.logger.notice("Cancelled \(isOn)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            let newIsOn = !isOn
                            SettingsManager.shared.saveOnline(newIsOn)
                            self?.configure()
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
        )
    }

    private func handleUserLogOut(shouldReload: Bool = true, completion: (() -> Void)? = nil) {
        UserSession.logOut()

        DispatchQueue.main.async { [weak self] in
            if shouldReload {
                self?.configure()
                self?.tableView.reloadData()
            }
            completion?()
        }
    }

    private func updateUIAfterDataTransfer(isOnline: Bool) {
        DispatchQueue.main.async {  // UI update
            self.logger.debug("Updating UI for online mode: \(isOnline)")
            SVProgressHUD.dismiss()
            SettingsManager.shared.saveOnline(isOnline)
            self.configure()
            self.tableView.reloadData()
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
}

// MARK: - Constraints
extension SettingListViewController {
    func setConstraints() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
    }
}
