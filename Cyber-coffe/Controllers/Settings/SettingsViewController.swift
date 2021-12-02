//
//  SettingsViewController.swift
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
    let handler: (() -> Void)
    let isOn: Bool
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

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
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
        configure()
        view.backgroundColor = UIColor.Main.background
        title = "Settings"
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.backgroundColor = UIColor.Main.background
        
    }
    
    func configure() {
        models.append(Section(title: "General", option: [
            .dataCell(model: SettingsDataOption(title: "Language", icon: UIImage(systemName: "globe"), iconBackgroundColor: .systemPink, data: "English") { dataLabel in
                //self.navigationController?.pushViewController(LanguageViewController(), animated: true)
                self.alertLanguage(label: dataLabel) { language in
                    print(language)
                }
            }),
            .switchCell(model: SettingsSwitchOption(title: "Dark Theme", icon: UIImage(systemName: "sun.max"), iconBackgroundColor: .systemBlue, handler: {
                print("Switch")
            }, isOn: true))
        ]))
        
        models.append(Section(title: "Sales", option: [
            .staticCell(model: SettingsStaticOption(title: "Goods", icon: UIImage(systemName: "cup.and.saucer.fill"), iconBackgroundColor: .systemGreen) {
                self.navigationController?.pushViewController(GoodsViewController(), animated: true)
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsStaticTableViewCell.identifier, for: indexPath) as? SettingsStaticTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .switchCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsSwitchTableViewCell.identifier, for: indexPath) as? SettingsSwitchTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        case .dataCell(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsDataTableViewCell.identifier, for: indexPath) as? SettingsDataTableViewCell else {
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
    
}
