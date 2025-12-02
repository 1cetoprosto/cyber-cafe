//
//  SceneDelegate.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import FirebaseAuth
import RealmSwift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, Loggable {
    
    static var shared: SceneDelegate {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let delegate = scene.delegate as? SceneDelegate
        else {
            fatalError("No active SceneDelegate instance found")
        }
        return delegate
    }
    
    var window: UIWindow?
    
    // MARK: Migration
    // Функція для налаштування Realm з міграцією
    func configureRealm() {
        // Визначте версію схеми як константу
        let currentSchemaVersion: UInt64 = 3
        
        // Визначте блок міграції
        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < currentSchemaVersion {
                // Приклад: Додавання нової властивості з початковим значенням
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: RealmProductModel.className()) {
                        oldObject, newObject in
                        newObject!["orderId"] = ""  // Initial value for a new property
                    }
                    
                    // Заповнення поля orderId відповідними значеннями з RealmOrderModel
                    migration.enumerateObjects(ofType: RealmOrderModel.className()) { oldObject, newObject in
                        if let orderId = oldObject!["id"] as? String,
                           let date = oldObject!["date"] as? Date
                        {
                            migration.enumerateObjects(ofType: RealmProductModel.className()) {
                                productOldObject, productNewObject in
                                if productOldObject!["date"] as? Date == date {
                                    productNewObject!["orderId"] = orderId
                                }
                            }
                        }
                    }
                }
                if oldSchemaVersion < 3 {
                    migration.enumerateObjects(ofType: RealmTypeModel.className()) { _, newObject in
                        newObject!["isDefault"] = false
                    }
                }
            }
        }
        
        // Налаштуйте Realm з новою версією схеми та блоком міграції
        let config = Realm.Configuration(
            schemaVersion: currentSchemaVersion,
            migrationBlock: migrationBlock
        )
        
        // Встановіть конфігурацію Realm за замовчуванням
        Realm.Configuration.defaultConfiguration = config
    }
    
    // MARK: Scene Lifecycle
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
        
        //configureRealm()
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        logger.info("Current system language code: \(Locale.current.languageCode ?? "N/A")")
        window = UIWindow(windowScene: windowScene)
        
        let isValidSession = UserSession.current.restore()
        if UserSession.current.hasOnlineVersion {
            // Перевірка наявності дійсної сесії користувача та відповідний перехід на потрібний екран
            if !isValidSession || Auth.auth().currentUser == nil {
                // Якщо сесія не дійсна або користувач не аутентифікований, переходимо на екран входу
                let signInController = SignInController()
                let navigationController = UINavigationController(rootViewController: signInController)
                navigationController.setNavigationBarHidden(true, animated: false)
                window?.rootViewController = navigationController
            } else {
                // Якщо сесія дійсна, переходимо на головний екран додатку
                window?.rootViewController = MainTabBarController()
            }
        } else {
            configureRealm()
            window?.rootViewController = MainTabBarController()
        }
        
    window?.makeKeyAndVisible()
    
    // Apply saved theme on app launch
    Theme.applyCurrentTheme()

    seedDefaultIncomeTypesIfNeeded()
  }
  
  func set(root controller: UIViewController) {
        let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
        controller.view.addSubview(overlayView)
        window?.rootViewController = controller
        
        UIView.animate(
            withDuration: 0.4, delay: 0, options: .transitionCrossDissolve,
            animations: {
                overlayView.alpha = 0
            },
            completion: { finished in
                overlayView.removeFromSuperview()
            })
  }
}

extension SceneDelegate {
    private func seedDefaultIncomeTypesIfNeeded() {
        let key = UserDefaultsKeys.firstLaunch
        let seeded = UserDefaults.standard.bool(forKey: key)
        if seeded { return }
        DomainDatabaseService.shared.fetchTypes { types in
            if !types.isEmpty {
                UserDefaults.standard.set(true, forKey: key)
                UserDefaults.standard.synchronize()
                return
            }
            let names = [
                R.string.global.typeHall(),
                R.string.global.typeTakeaway(),
                R.string.global.typeDelivery()
            ]
            let group = DispatchGroup()
            for name in names {
                group.enter()
                let model = TypeModel(id: UUID().uuidString, name: name)
                DomainDatabaseService.shared.saveType(model: model) { _ in
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                UserDefaults.standard.set(true, forKey: key)
                UserDefaults.standard.synchronize()
            }
        }
    }
}
