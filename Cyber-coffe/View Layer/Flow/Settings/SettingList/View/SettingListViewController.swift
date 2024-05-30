//
//  SettingListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
import RealmSwift
import SVProgressHUD
import FirebaseAuth

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

class SettingListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(SettingsStaticTableViewCell.self, forCellReuseIdentifier: SettingsStaticTableViewCell.identifier)
        table.register(SettingsSwitchTableViewCell.self, forCellReuseIdentifier: SettingsSwitchTableViewCell.identifier)
        table.register(SettingsDataTableViewCell.self, forCellReuseIdentifier: SettingsDataTableViewCell.identifier)
        
        return table
    }()
    
    var models = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.menuSettings()
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.backgroundColor = UIColor.Main.background
        
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configure()
        tableView.reloadData()
    }
    
    func configure() {
        
        models.removeAll()
        
        var options = [SettingsOptionType]()
        
        options.append(.dataCell(model: SettingsDataOption(title: "Language",
                                                           icon: UIImage(systemName: "globe"),
                                                           iconBackgroundColor: .systemPink,
                                                           data: SettingsManager.shared.loadLanguage()) { dataLabel in
            self.alertLanguage(label: dataLabel) { language in
                SettingsManager.shared.saveLanguage(language)
                dataLabel.text = language
            }
        }))
        
        options.append(.dataCell(model: SettingsDataOption(title: "Theme",
                                                           icon: UIImage(systemName: "sun.max"),
                                                           iconBackgroundColor: .systemBlue,
                                                           data: SettingsManager.shared.loadTheme()) { dataLabel in
            self.alertTheme(label: dataLabel) { style in
                Theme.currentThemeStyle = style
                SettingsManager.shared.saveTheme(style.themeName)
                dataLabel.text = style.themeName
                self.updateInterfaceForNewTheme()
            }
        }))
        
        if UserSession.current.hasOnlineVersion {
            options.append(.staticCell(model: SettingsStaticOption(title: "Exit",
                                                                   icon: UIImage(named: "exit"),
                                                                   iconBackgroundColor: .systemGreen) {
                UserSession.logOut()
            }))
        }
        
        models.append(Section(title: "General", option: options))
        
        models.append(Section(title: "Sales", option: [
            .staticCell(model: SettingsStaticOption(title: "Goods",
                                                    icon: UIImage(systemName: "cup.and.saucer.fill"),
                                                    iconBackgroundColor: .systemBrown) {
                                                        self.navigationController?.pushViewController(GoodListViewController(), animated: true)
                                                    })
        ]))
        
        models.append(Section(title: "Donation", option: [
            .staticCell(model: SettingsStaticOption(title: "Types",
                                                    icon: UIImage(systemName: "banknote.fill"),
                                                    iconBackgroundColor: .systemGreen) {
                                                        self.navigationController?.pushViewController(IncomeTypesListViewController(), animated: true)
                                                    })
        ]))
        
        models.append(Section(title: "Database", option: [
            .switchCell(model: SettingsSwitchOption(title: "Online",
                                                    icon: UIImage(systemName: "icloud.fill"),
                                                    iconBackgroundColor: .systemGreen,
                                                    isOn: SettingsManager.shared.loadOnline()) { isOn in
                                                        SettingsManager.shared.saveOnline(isOn)
                                                        print("Online mode is \(isOn ? "On" : "Off")")
                                                        self.toggleOfflineOnlineMode()
                                                        self.tableView.reloadData()
                                                    })
        ]))
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsStaticTableViewCell.identifier,
                                                           for: indexPath) as? SettingsStaticTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .switchCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsSwitchTableViewCell.identifier,
                                                           for: indexPath) as? SettingsSwitchTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .dataCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsDataTableViewCell.identifier,
                                                           for: indexPath) as? SettingsDataTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        }
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
    
    func switchToDarkTheme(isOn: Bool) {
        print("Tap to switchDarkTheme isOn: \(isOn)")
    }
    
    func updateInterfaceForNewTheme() {
        // Reload your tableview data after changing the theme
        //tableView.reloadData()
        // Update any other UI elements that may need to reflect the new theme
        // For example, you may need to update navigation bar appearance, etc.
        
        // Show an alert to inform the user to restart the app for the changes to take effect
        let alert = UIAlertController(title: R.string.global.restartRequired(), message: R.string.global.restartRequiredMsg(), preferredStyle: .alert)
        let okAction = UIAlertAction(title: R.string.global.actionOk(), style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func toggleOfflineOnlineMode() {
        PopupFactory.showPopup(
            title: "Перенесення даних",
            description: "Перенести накопиченні данні, чи розпочати все спочатку?",
            buttonTitle: R.string.global.confirm(),
            buttonAction: { [weak self] in
                SVProgressHUD.show(withStatus: "Триває перенесення даних...")
                
                self?.authenticateUser { [weak self] success in
                    guard success else {
                        SVProgressHUD.dismiss()
                        return
                    }
                    
                    if UserSession.current.hasOnlineVersion {
                        DomainDatabaseService.shared.transferDataFromRealmToFIR {
                            SVProgressHUD.dismiss()
                        }
                    } else {
                        DomainDatabaseService.shared.transferDataFromFIRToRealm {
                            //UserSession.logOut()
                            SVProgressHUD.dismiss()
                        }
                    }
                }
            },
            cancelAction: { [weak self] in
                self?.authenticateUser { success in
                    if success {
                        print("Якщо авторизація успішна, робіть тут що завгодно")
                        if !UserSession.current.hasOnlineVersion {
                            UserSession.logOut()
                        }
                    } else {
                        print("Обробте випадок, коли авторизація не вдалася")
                    }
                }
            }
        )
    }

    
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        if Auth.auth().currentUser == nil {
            // User is not authenticated, present the sign-in screen
            let signInController = SignInController()
            signInController.completionHandler = { success in
                DispatchQueue.main.async {
                    completion(success)
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
}

// MARK: - Constraints
extension SettingListViewController {
    func setConstraints() {
        
        let mainStackView = UIStackView(arrangedSubviews: [tableView],
                                        axis: .vertical,
                                        spacing: 10,
                                        distribution: .fill)
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
