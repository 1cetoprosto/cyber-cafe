//
//  SettingListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation

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
    let icon: String //UIImage?
    let iconBackgroundColor: String //UIColor
    let isOn: Bool
    let handler: (() -> Void)
}

struct SettingsStaticOption {
    let title: String
    let icon: String //UIImage?
    let iconBackgroundColor: String //UIColor
    let handler: (() -> Void)
}

struct SettingsDataOption {
    let title: String
    let icon: String //UIImage?
    let iconBackgroundColor: String //UIColor
    let data: String
    //let handler: ((_ dataLabel: UILabel) -> Void)
}

class SettingListViewModel: SettingListViewModelType {
    
    private var selectedIndexPath: IndexPath?
    private var settings: [Section]?
    
    func getSettings(completion: @escaping () -> ()) {
        settings.append(Section(title: R.string.global.general(), option: [
            .dataCell(model: SettingsDataOption(title: R.string.global.language(),
                                                icon: "globe", //UIImage(systemName: "globe"),
                                                iconBackgroundColor: "systemPink", //.systemPink,
                                                data: DefaultValues.defaultLanguage) { dataLabel in
                self.alertLanguage(label: dataLabel) { language in
                    print(language)
                }
            }),
            .switchCell(model: SettingsSwitchOption(title: R.string.global.darkTheme(),
                                                    icon: SystemImages.sunMax, //UIImage(systemName: "sun.max"),
                                                    iconBackgroundColor: "systemBlue", //.systemBlue,
                                                    isOn: true) {
                self.switchToDarkTheme(isOn: true)
            })
        ]))

        settings.append(Section(title: R.string.global.sales(), option: [
            .staticCell(model: SettingsStaticOption(title: R.string.global.goods(),
                                                    icon: SystemImages.cupAndSaucerFill, //UIImage(systemName: "cup.and.saucer.fill"),
                                                    iconBackgroundColor: "systemGreen", //.systemGreen) {
                self.navigationController?.pushViewController(GoodListViewController(), animated: true)
            })
        ]))
        
        completion()
    }
    
    func numberOfRowInSection(for section: Int) -> Int {
        guard let settings = self.settings else { return 0 }
        return settings.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> SettingListItemViewModelType? {
        guard let settings = self.settings else { return nil }
        let setting = settings[indexPath.row]
        return SettingsListItemViewModel(setting: setting)
    }
    
//    func viewModelForSelectedRow() -> PurchaseDetailsViewModelType? {
//        guard let selectedIndexPath = selectedIndexPath,
//              let purchases = self.purchases else { return nil }
//        let purchase = purchases[selectedIndexPath.row]
//        return PurchaseDetailsViewModel(purchase: purchase)
//    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
    }
}
