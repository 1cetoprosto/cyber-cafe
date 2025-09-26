//
//  SceneDelegate.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import FirebaseAuth
import RealmSwift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

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
    let currentSchemaVersion: UInt64 = 2  // Збільшуйте це число при кожній міграції

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
