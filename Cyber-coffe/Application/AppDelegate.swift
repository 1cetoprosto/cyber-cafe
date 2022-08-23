//
//  AppDelegate.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UINavigationBar.appearance().customNavigationBar()
        FirebaseApp.configure()
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
