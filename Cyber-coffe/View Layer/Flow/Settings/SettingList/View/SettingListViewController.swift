//
//  SettingListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

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

class SettingListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(SettingsStaticTableViewCell.self, forCellReuseIdentifier: SettingsStaticTableViewCell.identifier)
        table.register(SettingsSwitchTableViewCell.self, forCellReuseIdentifier: SettingsSwitchTableViewCell.identifier)
        table.register(SettingsDataTableViewCell.self, forCellReuseIdentifier: SettingsDataTableViewCell.identifier)
        
        return table
    }()
    
    private lazy var updateDataButton: UIButton = {
        let button = DefaultButton()
        button.setTitle("Erase & download data from server", for: .normal)
        button.addTarget(self, action: #selector(updateDataAction), for: .touchUpInside)
        
        return button
    }()
    
    var models = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.menuSettings()
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.backgroundColor = UIColor.Main.background
        
        view.addSubview(updateDataButton)
        setConstraints()
    }
    
//    func configure() {
//        models.append(Section(title: "General", option: [
//            .dataCell(model: SettingsDataOption(title: "Language",
//                                                icon: UIImage(systemName: "globe"),
//                                                iconBackgroundColor: .systemPink,
//                                                data: "English") { dataLabel in
//                                                    self.alertLanguage(label: dataLabel) { language in
//                                                        print(language)
//                                                    }
//                                                }),
//            .dataCell(model: SettingsDataOption(title: "Theme",
//                                                icon: UIImage(systemName: "sun.max"),
//                                                iconBackgroundColor: .systemBlue,
//                                                data: Theme.currentThemeStyle.themeName) {  dataLabel in
//                                                    self.alertTheme(label: dataLabel) { style in
//                                                        print("Befor - \(Theme.currentThemeStyle)")
//                                                        Theme.currentThemeStyle = style
//                                                        print("After - \(Theme.currentThemeStyle)")
//                                                        self.updateInterfaceForNewTheme()
//                                                    }
//                                                }),
//            .staticCell(model: SettingsStaticOption(title: "Exit",
//                                                    icon: UIImage(named: "exit"),
//                                                    iconBackgroundColor: .systemGreen) {
//                                                        UserSession.logOut()
//                                                    })
//        ]))
//        
//        models.append(Section(title: "Sales", option: [
//            .staticCell(model: SettingsStaticOption(title: "Goods",
//                                                    icon: UIImage(systemName: "cup.and.saucer.fill"),
//                                                    iconBackgroundColor: .systemBrown) {
//                                                        self.navigationController?.pushViewController(GoodListViewController(), animated: true)
//                                                    })
//        ]))
//        
//        models.append(Section(title: "Donation", option: [
//            .staticCell(model: SettingsStaticOption(title: "Types",
//                                                    icon: UIImage(systemName: "banknote.fill"),
//                                                    iconBackgroundColor: .systemGreen) {
//                                                        self.navigationController?.pushViewController(IncomeTypesListViewController(), animated: true)
//                                                    })
//        ]))
//        
//        models.append(Section(title: "Database", option: [
//            .staticCell(model: SettingsStaticOption(title: "Online",
//                                                    icon: UIImage(systemName: "icloud.fill"),
//                                                    iconBackgroundColor: .systemGreen) {
//                                                        self.navigationController?.pushViewController(IncomeTypesListViewController(), animated: true)
//                                                    }),
//            .switchCell(model: SettingsSwitchOption(title: "Online",
//                                                    icon: UIImage(systemName: "icloud.fill"),
//                                                    iconBackgroundColor: .systemGreen,
//                                                    isOn: false, handler: {
//                                                        print(<#T##items: Any...##Any#>)
//                                                    }))
//        ]))
//        
//    }
    
    func configure() {
        models.append(Section(title: "General", option: [
            .dataCell(model: SettingsDataOption(title: "Language",
                                                icon: UIImage(systemName: "globe"),
                                                iconBackgroundColor: .systemPink,
                                                data: SettingsManager.shared.loadLanguage()) { dataLabel in
                                                    self.alertLanguage(label: dataLabel) { language in
                                                        SettingsManager.shared.saveLanguage(language)
                                                        dataLabel.text = language
                                                    }
                                                }),
            .dataCell(model: SettingsDataOption(title: "Theme",
                                                icon: UIImage(systemName: "sun.max"),
                                                iconBackgroundColor: .systemBlue,
                                                data: SettingsManager.shared.loadTheme()) { dataLabel in
                                                    self.alertTheme(label: dataLabel) { style in
                                                        Theme.currentThemeStyle = style
                                                        SettingsManager.shared.saveTheme(style.themeName)
                                                        dataLabel.text = style.themeName
                                                        self.updateInterfaceForNewTheme()
                                                    }
                                                }),
            .staticCell(model: SettingsStaticOption(title: "Exit",
                                                    icon: UIImage(named: "exit"),
                                                    iconBackgroundColor: .systemGreen) {
                                                        UserSession.logOut()
                                                    })
        ]))

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
//            .staticCell(model: SettingsStaticOption(title: "Online",
//                                                    icon: UIImage(systemName: "icloud.fill"),
//                                                    iconBackgroundColor: .systemGreen) {
//                                                        self.navigationController?.pushViewController(IncomeTypesListViewController(), animated: true)
//                                                    }),
            .switchCell(model: SettingsSwitchOption(title: "Online",
                                                    icon: UIImage(systemName: "icloud.fill"),
                                                    iconBackgroundColor: .systemGreen,
                                                    isOn: SettingsManager.shared.loadOnline()) { isOn in
                                                        SettingsManager.shared.saveOnline(isOn)
                                                        print("Online mode is \(isOn ? "On" : "Off")")
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
    
    @objc func updateDataAction(sender: UIButton!) {
        
        //TODO: видати питання, чи ви впевнені що хочете це зробити
        
//        // erase Realm
//        RealmDatabaseService.shared.deleteAllData()
//        
//        FirestoreDatabaseService.shared.read(collection: "sales", firModel: FIRDailySalesModel.self) { firSales in
//            for (documentId, firSalesModel) in firSales {
//                RealmDatabaseService.shared.save(model: RealmDailySalesModel(documentId: documentId, firModel: firSalesModel))
//            }
//        }
//        
//        FirestoreDatabaseService.shared.read(collection: "saleGood", firModel: FIRSaleGoodModel.self) { firSaleGoods in
//            for (documentId, firSaleGoodModel) in firSaleGoods {
//                RealmDatabaseService.shared.save(model: RealmSaleGoodModel(documentId: documentId, firModel: firSaleGoodModel))
//            }
//        }
//        
//        FirestoreDatabaseService.shared.read(collection: "purchase", firModel: FIRPurchaseModel.self) { firPurchases in
//            for (documentId, firPurchaseModel) in firPurchases {
//                RealmDatabaseService.shared.save(model: RealmPurchaseModel(documentId: documentId, firModel: firPurchaseModel))
//            }
//        }
//        
//        FirestoreDatabaseService.shared.read(collection: "goodsPrice", firModel: FIRGoodsPriceModel.self) { firGoodsPrice in
//            for (documentId, firGoodsPriceModel) in firGoodsPrice {
//                RealmDatabaseService.shared.save(model: RealmGoodsPriceModel(documentId: documentId, firModel: firGoodsPriceModel))
//            }
//        }
//        
//        FirestoreDatabaseService.shared.read(collection: "typesOfDonation", firModel: FIRIncomeTypeModel.self) { firTypeOfDonations in
//            for (documentId, firTypeOfDonationModel) in firTypeOfDonations {
//                RealmDatabaseService.shared.save(model: RealmIncomeTypeModel(documentId: documentId, firModel: firTypeOfDonationModel))
//            }
//        }
    }
}

// MARK: - Constraints
extension SettingListViewController {
    func setConstraints() {
        
        NSLayoutConstraint.activate([
            updateDataButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let mainStackView = UIStackView(arrangedSubviews: [tableView, updateDataButton],
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
