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
    let handler: (() -> Void)
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
    
    private lazy var updateData: UIButton = {
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
        title = "Settings"
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.backgroundColor = UIColor.Main.background
        
        view.addSubview(updateData)
        setConstraints()
    }

    func configure() {
        models.append(Section(title: "General", option: [
            .dataCell(model: SettingsDataOption(title: "Language",
                                                icon: UIImage(systemName: "globe"),
                                                iconBackgroundColor: .systemPink,
                                                data: "English") { dataLabel in
                self.alertLanguage(label: dataLabel) { language in
                    print(language)
                }
            }),
            .switchCell(model: SettingsSwitchOption(title: "Dark Theme",
                                                    icon: UIImage(systemName: "sun.max"),
                                                    iconBackgroundColor: .systemBlue,
                                                    isOn: true) {
                self.switchToDarkTheme(isOn: true)
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
                self.navigationController?.pushViewController(TypesListViewController(), animated: true)
            })
        ]))
        
        models.append(Section(title: "Synhronize", option: [
            .staticCell(model: SettingsStaticOption(title: "Synhronize",
                                                    icon: UIImage(systemName: "banknote.fill"),
                                                    iconBackgroundColor: .systemGreen) {
                self.navigationController?.pushViewController(TypesListViewController(), animated: true)
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
        case .switchCell(let model):
            model.handler()
        case .dataCell(let model):
            let cell = tableView.cellForRow(at: indexPath) as! SettingsDataTableViewCell
            model.handler(cell.dataLabel)
        }
    }

    func switchToDarkTheme(isOn: Bool) {
        print("Tap to switchDarkTheme isOn: \(isOn)")
    }
    
    @objc func updateDataAction(sender: UIButton!) {
        
        //видати питання, чи ви впевнені що хочете це зробити
        
        // erase Realm
        DatabaseManager.shared.deleteAllData()
        
        FIRFirestoreService.shared.read(collection: "sales", firModel: FIRSalesModel.self) { firSales in
            for (documentId, firSalesModel) in firSales {
                DatabaseManager.shared.save(model: SalesModel(documentId: documentId, firModel: firSalesModel))
            }
        }
        
        FIRFirestoreService.shared.read(collection: "saleGood", firModel: FIRSaleGoodModel.self) { firSaleGoods in
            for (documentId, firSaleGoodModel) in firSaleGoods {
                DatabaseManager.shared.save(model: SaleGoodModel(documentId: documentId, firModel: firSaleGoodModel))
            }
        }
        
        FIRFirestoreService.shared.read(collection: "purchase", firModel: FIRPurchaseModel.self) { firPurchases in
            for (documentId, firPurchaseModel) in firPurchases {
                DatabaseManager.shared.save(model: PurchaseModel(documentId: documentId, firModel: firPurchaseModel))
            }
        }
        
        FIRFirestoreService.shared.read(collection: "goodsPrice", firModel: FIRGoodsPriceModel.self) { firGoodsPrice in
            for (documentId, firGoodsPriceModel) in firGoodsPrice {
                DatabaseManager.shared.save(model: GoodsPriceModel(documentId: documentId, firModel: firGoodsPriceModel))
            }
        }
        
        FIRFirestoreService.shared.read(collection: "typesOfDonation", firModel: FIRTypeOfDonationModel.self) { firTypeOfDonations in
            for (documentId, firTypeOfDonationModel) in firTypeOfDonations {
                DatabaseManager.shared.save(model: TypeOfDonationModel(documentId: documentId, firModel: firTypeOfDonationModel))
            }
        }
    }
}

// MARK: - Constraints
extension SettingListViewController {
    func setConstraints() {

//        let cashStackView = UIStackView(arrangedSubviews: [moneyLabel, moneyTextfield],
//                                        axis: .horizontal,
//                                        spacing: 5,
//                                        distribution: .equalSpacing)
//        view.addSubview(cashStackView)
//
//        let moneyStackView = UIStackView(arrangedSubviews: [cashStackView, saleLabel],
//                                         axis: .horizontal,
//                                         spacing: 10,
//                                         distribution: .fillEqually)
//        view.addSubview(moneyStackView)

        NSLayoutConstraint.activate([
            updateData.heightAnchor.constraint(equalToConstant: 50)
        ])

        let mainStackView = UIStackView(arrangedSubviews: [tableView, updateData],
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
