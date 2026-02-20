//
//  SettingListViewModel.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation

// Structs moved/duplicated in SettingListViewController.swift - commenting out to avoid redeclaration errors
//struct Section {
//    let title: String
//    let option: [SettingsOptionType]
//}
//
//enum SettingsOptionType {
//    case staticCell(model: SettingsStaticOption)
//    case switchCell(model: SettingsSwitchOption)
//    case dataCell(model: SettingsDataOption)
//}
//
//struct SettingsSwitchOption {
//    let title: String
//    let icon: String //UIImage?
//    let iconBackgroundColor: String //UIColor
//    let isOn: Bool
//    let handler: (() -> Void)
//}
//
//struct SettingsStaticOption {
//    let title: String
//    let icon: String //UIImage?
//    let iconBackgroundColor: String //UIColor
//    let handler: (() -> Void)
//}
//
//struct SettingsDataOption {
//    let title: String
//    let icon: String //UIImage?
//    let iconBackgroundColor: String //UIColor
//    let data: String
//    //let handler: ((_ dataLabel: UILabel) -> Void)
//}

class SettingListViewModel: SettingListViewModelType {

  private var selectedIndexPath: IndexPath?
  // Using explicit types from ViewController if needed, or commenting out usage since this VM seems unused
  // private var settings: [Section] = []

  func getSettings(completion: @escaping () -> Void) {
    // settings = []
    // settings.append(Section(title: R.string.global.general(), option: [
    //    ...
    // ]))
    completion()
  }

  func numberOfRowInSection(for section: Int) -> Int {
    // guard let settings = self.settings else { return 0 }
    // return settings.count
    return 0
  }

  func cellViewModel(for indexPath: IndexPath) -> SettingListItemViewModelType? {
    // guard let settings = self.settings else { return nil }
    // let setting = settings[indexPath.row]
    // return SettingsListItemViewModel(setting: setting)
    return nil
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
