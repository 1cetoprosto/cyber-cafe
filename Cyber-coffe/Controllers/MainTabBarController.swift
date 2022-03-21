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

        //view.backgroundColor = .green
        setupTabBar()
        self.tabBar.tintColor = UIColor.TabBar.tint
        navigationController?.view.backgroundColor = UIColor.NavBar.background
    }

    func setupTabBar() {
        let salesViewController = createNavController(vc: SalesViewController(), itemName: "Sales", itemImage: "cup.and.saucer.fill")
        let purchasesViewController = createNavController(vc: PurchasesViewController(), itemName: "Purchases", itemImage: "takeoutbag.and.cup.and.straw.fill")
        let settingsViewController = createNavController(vc: SettingsViewController(), itemName: "Settings", itemImage: "gearshape")
        
        viewControllers = [salesViewController, purchasesViewController, settingsViewController]
    }
    
    func createNavController(vc: UIViewController, itemName: String, itemImage: String) -> UINavigationController{
        let item = UITabBarItem(title: itemName, image: UIImage(systemName: itemImage), tag: 0) //?.withAlignmentRectInsets(.init(top: 10, left: 0, bottom: 0, right: 0))
        //item.titlePositionAdjustment = .init(horizontal: 0, vertical: 10)
        
        let navController = UINavigationController(rootViewController: vc)
        navController.tabBarItem = item
        navController.view.backgroundColor = UIColor.NavBar.background
        
        return navController
    }


}

