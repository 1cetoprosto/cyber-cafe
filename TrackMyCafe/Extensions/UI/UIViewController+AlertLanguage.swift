//
//  AlertLanguage.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.12.2021.
//

import UIKit

extension UIViewController {

  func alertLanguage(label: UILabel, completionHandle: @escaping (String) -> Void) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

    let english = UIAlertAction(title: R.string.global.english(), style: .default) { _ in
      label.text = R.string.global.english()
      let typeContact = R.string.global.english()
      completionHandle(typeContact)
    }

    //        let russian = UIAlertAction(title: "Русский", style: .default) { _ in
    //            label.text = "Русский"
    //            let typeContact = "Русский"
    //            completionHandle(typeContact)
    //        }

    let ukrainian = UIAlertAction(title: R.string.global.ukrainian(), style: .default) { _ in
      label.text = R.string.global.ukrainian()
      let typeContact = R.string.global.ukrainian()
      completionHandle(typeContact)
    }

    let cansel = UIAlertAction(title: R.string.global.cancel(), style: .cancel)

    alert.addAction(english)
    //alert.addAction(russian)
    alert.addAction(ukrainian)
    alert.addAction(cansel)

    present(alert, animated: true)

  }

  func alertTheme(label: UILabel, completionHandle: @escaping (ThemeStyle) -> Void) {
    let alert = UIAlertController(
      title: R.string.global.selectTheme(), message: nil, preferredStyle: .actionSheet)

    for style in ThemeStyle.allCases {
      let action = UIAlertAction(title: style.themeName, style: .default) { _ in
        label.text = style.themeName
        completionHandle(style)
      }
      alert.addAction(action)
    }

    let cancelAction = UIAlertAction(title: R.string.global.cancel(), style: .cancel)
    alert.addAction(cancelAction)

    present(alert, animated: true)
  }
}
