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
        
        configureFirebase()
        configureSVProgressHUD()
        setupAppearance()
        
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
    
    // MARK: - Private Methods
    
    private func configureFirebase() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
    }
    
    private func configureSVProgressHUD() {
        SVProgressHUD.setBackgroundColor(UIColor(white: 0, alpha: 0.4))
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(1)
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
}
