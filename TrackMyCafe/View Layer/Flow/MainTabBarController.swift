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
    applyTabBarAppearance()
    navigationController?.view.backgroundColor = UIColor.NavBar.background
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    // Handle system theme changes only if user has selected system appearance
    if Theme.currentSelection.appearance == .system {
      Theme.followSystemTheme()

      // Update UI colors for current interface
      updateInterfaceColors()
    }
  }

  private func updateInterfaceColors() {
    // Update tab bar colors
    applyTabBarAppearance()
    navigationController?.view.backgroundColor = UIColor.NavBar.background

    // Update all child navigation controllers
    viewControllers?.forEach { viewController in
      if let navController = viewController as? UINavigationController {
        navController.view.backgroundColor = UIColor.NavBar.background
      }
    }
  }

  // Configure UITabBarAppearance to ensure good contrast for selected/unselected icons
  private func applyTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = Theme.current.primaryBackground

    // Unified selected/unselected icon colors across palettes
    let selectedColor: UIColor = Theme.current.tabBarTint

    // Unselected color sourced from theme for consistency across palettes
    let unselectedColor = Theme.current.tabBarUnselectedTint

    // Apply to stacked layout
    let stacked = appearance.stackedLayoutAppearance
    stacked.selected.iconColor = selectedColor
    stacked.selected.titleTextAttributes = [
      .foregroundColor: selectedColor,
      .font: Typography.footnote,
    ]
    stacked.normal.iconColor = unselectedColor
    stacked.normal.titleTextAttributes = [
      .foregroundColor: unselectedColor,
      .font: Typography.footnote,
    ]

    // Apply to inline layout
    let inline = appearance.inlineLayoutAppearance
    inline.selected.iconColor = selectedColor
    inline.selected.titleTextAttributes = [
      .foregroundColor: selectedColor,
      .font: Typography.footnote,
    ]
    inline.normal.iconColor = unselectedColor
    inline.normal.titleTextAttributes = [
      .foregroundColor: unselectedColor,
      .font: Typography.footnote,
    ]

    // Apply to compact inline layout
    let compact = appearance.compactInlineLayoutAppearance
    compact.selected.iconColor = selectedColor
    compact.selected.titleTextAttributes = [
      .foregroundColor: selectedColor,
      .font: Typography.footnote,
    ]
    compact.normal.iconColor = unselectedColor
    compact.normal.titleTextAttributes = [
      .foregroundColor: unselectedColor,
      .font: Typography.footnote,
    ]

    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }

    // Keep legacy properties in sync (used by some UIKit APIs)
    tabBar.tintColor = selectedColor
    tabBar.unselectedItemTintColor = unselectedColor
  }

  func setupTabBar() {
    let ordersViewController = createNavController(
      viewController: OrderListViewController(),
      itemName: R.string.global.orders(),
      itemImage: SystemImages.cupAndSaucerFill)
    let costsViewController = createNavController(
      viewController: CostListViewController(),
      itemName: R.string.global.costs(),
      itemImage: SystemImages.takeoutbagAndCupAndStrawFill)
    let settingsViewController = createNavController(
      viewController: SettingListViewController(),
      itemName: R.string.global.menuSettings(),
      itemImage: SystemImages.gearshape)

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

    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithOpaqueBackground()
    navAppearance.backgroundColor = UIColor.NavBar.background
    navAppearance.titleTextAttributes = [
      .foregroundColor: UIColor.NavBar.title,
      .font: Typography.title3DemiBold,
    ]
    navAppearance.largeTitleTextAttributes = [
      .foregroundColor: UIColor.NavBar.title,
      .font: Typography.largeTitle,
    ]

    let buttonAppearance = UIBarButtonItemAppearance()
    buttonAppearance.normal.titleTextAttributes = [
      .foregroundColor: UIColor.NavBar.title,
      .font: Typography.body,
    ]
    buttonAppearance.highlighted.titleTextAttributes = [
      .foregroundColor: UIColor.NavBar.title,
      .font: Typography.bodyMedium,
    ]
    navAppearance.buttonAppearance = buttonAppearance
    navAppearance.doneButtonAppearance = buttonAppearance
    navAppearance.backButtonAppearance = buttonAppearance

    navController.navigationBar.standardAppearance = navAppearance
    if #available(iOS 15.0, *) {
      navController.navigationBar.scrollEdgeAppearance = navAppearance
    }
    navController.navigationBar.prefersLargeTitles = true

    return navController
  }

}
