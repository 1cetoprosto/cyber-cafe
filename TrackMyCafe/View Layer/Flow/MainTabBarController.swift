//
//  ViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import UIKit

class MainTabBarController: UITabBarController {

  override func viewDidLoad() {
    super.viewDidLoad()

    setupTabBar()
    self.tabBar.tintColor = UIColor.TabBar.tint
    navigationController?.view.backgroundColor = UIColor.NavBar.background
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    // Handle system theme changes only if user has selected "system" theme
    if Theme.currentThemeStyle == .system {
      let currentSystemTheme = traitCollection.userInterfaceStyle == .dark ? ThemeStyle.dark : ThemeStyle.light
      Theme.followSystemTheme()
      
      // Update UI colors for current interface
      updateInterfaceColors()
    }
  }
  
  private func updateInterfaceColors() {
    // Update tab bar colors
    self.tabBar.tintColor = UIColor.TabBar.tint
    navigationController?.view.backgroundColor = UIColor.NavBar.background
    
    // Update all child navigation controllers
    viewControllers?.forEach { viewController in
      if let navController = viewController as? UINavigationController {
        navController.view.backgroundColor = UIColor.NavBar.background
      }
    }
  }

  func setupTabBar() {
    let ordersViewController = createNavController(
      viewController: OrderListViewController(),
      itemName: R.string.global.orders(),
      itemImage: "cup.and.saucer.fill")
    let costsViewController = createNavController(
      viewController: CostListViewController(),
      itemName: R.string.global.costs(),
      itemImage: "takeoutbag.and.cup.and.straw.fill")
    let settingsViewController = createNavController(
      viewController: SettingListViewController(),
      itemName: R.string.global.menuSettings(),
      itemImage: "gearshape")

    viewControllers = [ordersViewController, costsViewController, settingsViewController]
  }

  func createNavController(
    viewController: UIViewController,
    itemName: String,
    itemImage: String
  ) -> UINavigationController {
    let item = UITabBarItem(title: itemName, image: UIImage(systemName: itemImage), tag: 0)

    let navController = UINavigationController(rootViewController: viewController)
    navController.tabBarItem = item
    navController.view.backgroundColor = UIColor.NavBar.background

    return navController
  }

}
