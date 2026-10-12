//
//  AlertLanguage.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.12.2021.
//

import UIKit

extension UIViewController {

  func alertLanguage(label: UILabel, completionHandle: @escaping (String) -> Void) {
    let actions: [PopupAction] = [
      PopupAction(title: R.string.global.english()) {
        label.text = R.string.global.english()
        completionHandle(R.string.global.english())
      },
      PopupAction(title: R.string.global.ukrainian()) {
        label.text = R.string.global.ukrainian()
        completionHandle(R.string.global.ukrainian())
      },
      PopupAction(title: R.string.global.cancel(), style: .cancel)
    ]
    PopupFactory.showActionSheet(actions: actions)
  }

  func alertTheme(label: UILabel, completionHandle: @escaping (ThemeOption) -> Void) {
    var actions = ThemeOption.allCases.map { option in
      PopupAction(title: option.displayName) {
        label.text = option.displayName
        completionHandle(option)
      }
    }
    actions.append(PopupAction(title: R.string.global.cancel(), style: .cancel))
    PopupFactory.showActionSheet(title: R.string.global.selectTheme(), actions: actions)
  }
}
