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

    func setupTabBar() {
        let salesViewController = createNavController(viewController: SaleListViewController(),
                                                      itemName: "Donations",
                                                      itemImage: "cup.and.saucer.fill")
        let purchasesViewController = createNavController(viewController: PurchaseListViewController(),
                                                          itemName: "Purchases",
                                                          itemImage: "takeoutbag.and.cup.and.straw.fill")
        let settingsViewController = createNavController(viewController: SettingListViewController(),
                                                         itemName: "Settings",
                                                         itemImage: "gearshape")

        viewControllers = [salesViewController, purchasesViewController, settingsViewController]
    }

    func createNavController(viewController: UIViewController,
                             itemName: String,
                             itemImage: String) -> UINavigationController {
        let item = UITabBarItem(title: itemName, image: UIImage(systemName: itemImage), tag: 0)
        
        let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem = item
        navController.view.backgroundColor = UIColor.NavBar.background

        return navController
    }

}
