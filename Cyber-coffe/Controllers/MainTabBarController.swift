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
    }

    func setupTabBar() {
        let scheduleViewController = createNavController(vc: SalesViewController(), itemName: "Продажи", itemImage: "cup.and.saucer.fill")
        let tasksViewController = createNavController(vc: PurchasesViewController(), itemName: "Закупки", itemImage: "takeoutbag.and.cup.and.straw.fill")
        let contactsViewController = createNavController(vc: SettingsViewController(), itemName: "Настройки", itemImage: "gearshape")
        
        viewControllers = [scheduleViewController, tasksViewController, contactsViewController]
    }
    
    func createNavController(vc: UIViewController, itemName: String, itemImage: String) -> UINavigationController{
        let item = UITabBarItem(title: itemName, image: UIImage(systemName: itemImage), tag: 0) //?.withAlignmentRectInsets(.init(top: 10, left: 0, bottom: 0, right: 0))
        //item.titlePositionAdjustment = .init(horizontal: 0, vertical: 10)
        
        let navController = UINavigationController(rootViewController: vc)
        navController.tabBarItem = item
        
        return navController
    }


}

