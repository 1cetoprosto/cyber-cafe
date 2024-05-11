//
//  SceneDelegate.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static var shared: SceneDelegate {
        guard let scene = UIApplication.shared.connectedScenes.first, let delegate = scene.delegate as? SceneDelegate else {
            fatalError("No active SceneDelegate instance found")
        }
        return delegate
    }
    
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        //window?.rootViewController = MainTabBarController()
        // В SceneDelegate не потрібно налаштовувати Firebase, це робиться в AppDelegate
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        window?.rootViewController = appDelegate.window?.rootViewController
        
        // Перевірка наявності дійсної сесії користувача та відповідний перехід на потрібний екран
        let isValidSession = UserSession.current.restore()
        if !isValidSession || Auth.auth().currentUser == nil {
            // Якщо сесія не дійсна або користувач не аутентифікований, переходимо на екран входу
            let signInController = SignInController()
            let navigationController = UINavigationController(rootViewController: signInController)
            navigationController.setNavigationBarHidden(true, animated: false)
            window?.rootViewController = navigationController
        } else {
            // Якщо сесія дійсна, переходимо на головний екран додатку
            let mainTabBarController = MainTabBarController()
            window?.rootViewController = mainTabBarController
        }
        
        window?.makeKeyAndVisible()
    }
    
    func set(root controller: UIViewController) {
        let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
        controller.view.addSubview(overlayView)
        window?.rootViewController = controller
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
            overlayView.alpha = 0
        }, completion: { finished in
            overlayView.removeFromSuperview()
        })
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later,
        // as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}
