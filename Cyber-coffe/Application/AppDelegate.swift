//
//  AppDelegate.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import SVProgressHUD

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate! as! AppDelegate
    }
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UINavigationBar.appearance().customNavigationBar()
        
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        
        setupAppearance()
        
        SVProgressHUD.setBackgroundColor(UIColor(white: 0, alpha: 0.4))
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1)
        
        //loadAllData()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running,
        // this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func setupAppearance() {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.NavBar.text]
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.NavBar.text]
            navBarAppearance.backgroundColor = UIColor.NavBar.background
            let appearance = UINavigationBar.appearance(whenContainedInInstancesOf: [MainNavigationController.self])
            appearance.standardAppearance = navBarAppearance
            appearance.compactAppearance = navBarAppearance
            appearance.scrollEdgeAppearance = navBarAppearance
            appearance.prefersLargeTitles = false
            appearance.isTranslucent = false
            appearance.tintColor = UIColor.NavBar.text
        } else {
            UINavigationBar.appearance().barTintColor = UIColor.NavBar.text
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.NavBar.text]
            UINavigationBar.appearance().isTranslucent = false
        }
        if #available(iOS 13.4, *) {
            UIDatePicker.appearance().preferredDatePickerStyle = .wheels
        }
    }
    
//    func loadAllData() {
//        // erase Realm
//        DatabaseManager.shared.deleteAllData()
//        
//        let firSales: [(documentId: String, FIRSalesModel)] = FIRFirestoreService.shared.read(collection: "sales")
//        for (documentId, firSalesModel) in firSales {
//            DatabaseManager.shared.saveSalesModel(model: SalesModel(documentId: documentId, firModel: firSalesModel))
//        }
//        
//        let firSaleGoods: [(documentId: String, FIRSaleGoodModel)] = FIRFirestoreService.shared.read(collection: "saleGood")
//        for (documentId, firSaleGoodModel) in firSaleGoods {
//            DatabaseManager.shared.saveSalesGoodModel(model: SaleGoodModel(documentId: documentId, firModel: firSaleGoodModel))
//        }
//        
//        let firPurchases: [(documentId: String, FIRPurchaseModel)] = FIRFirestoreService.shared.read(collection: "purchase")
//        for (documentId, firPurchaseModel) in firPurchases {
//            DatabaseManager.shared.savePurchaseModel(model: PurchaseModel(documentId: documentId, firModel: firPurchaseModel))
//        }
//        
//        let firGoodsPrice: [(documentId: String, FIRGoodsPriceModel)] = FIRFirestoreService.shared.read(collection: "goodsPrice")
//        for (documentId, firGoodsPriceModel) in firGoodsPrice {
//            DatabaseManager.shared.saveGoodsPriceModel(model: GoodsPriceModel(documentId: documentId, firModel: firGoodsPriceModel))
//        }
//        
//        let firTypeOfDonations: [(documentId: String, FIRTypeOfDonationModel)] = FIRFirestoreService.shared.read(collection: "typesOfdonation")
//        for (documentId, firTypeOfDonationModel) in firTypeOfDonations {
//            DatabaseManager.shared.saveTypeOfDonationModel(model: TypeOfDonationModel(documentId: documentId, firModel: firTypeOfDonationModel))
//        }
//    }
    
}
