//
//  UINavigationBar.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 22.11.2021.
//

import UIKit

extension UINavigationBar {
    func customNavigationBar() {
        // color for button images, indicators and etc.
        self.tintColor = UIColor.NavBar.text

        // color for background of navigation bar
        // but if you use larget titles, then in viewDidLoad must write
        // navigationController?.view.backgroundColor = // your color
        self.barTintColor = UIColor.NavBar.background
        self.isTranslucent = false

        // for larget titles
        // self.prefersLargeTitles = true

        // color for large title label
        // self.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]

        // color for standard title label
        self.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.NavBar.text]

        // remove bottom line/shadow
        // self.setBackgroundImage(UIImage(), for: .default)
        // self.shadowImage = UIImage()
    }
}
