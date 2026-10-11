//
//  SceneDelegate.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import FirebaseAuth
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

    // MARK: Scene Lifecycle
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        logger.info("Current system language code: \(Locale.currentLanguageCode ?? "N/A")")

        // Check for fresh install
        checkFreshInstall()

        window = UIWindow(windowScene: windowScene)
        guard let window else { return }

        // Apply saved theme immediately (before showing UI)
        Theme.apply(to: window)

        // Configure global UI appearance after window is ready
        setupAppearance()

        #if DEBUG
            // Reset subscription state for testing
            // IAPManager.shared.debugResetSubscription()
            // UserDefaults.standard.set(false, forKey: UserDefaultsKeys.hasSeenInitialPaywall)
        #endif

        start()
        window.makeKeyAndVisible()

        // Debug Logging of App State
        logAppState()

        seedDefaultIncomeTypesIfNeeded()

        buildDefaultOnboardingRegistry()
        #if canImport(Instructions)
            OnboardingManager.shared.configure(driver: InstructionsDriver())
        #endif
    }

    func start() {
        // 1. Check Onboarding
        let hasSeenOnboarding = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.hasSeenOnboarding)
        if !hasSeenOnboarding {
            let onboardingVC = OnboardingViewController()
            onboardingVC.delegate = self
            window?.rootViewController = onboardingVC
            return
        }
        // Set onboarding as seen implicitly to avoid showing it later if re-enabled
        // UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenOnboarding)

        // 2. Check Subscription (Moved to inside app via ProGated)
        /*
        let isPro = IAPManager.shared.isProPlan == true
        let hasSeenPaywall = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasSeenInitialPaywall)

        if !isPro && !hasSeenPaywall {
            let paywallVC = SubscriptionController.makeDefault()
            paywallVC.enableReadOnlyMode()
            paywallVC.onSubscriptionSuccess = { [weak self] in
                self?.start()
            }
            paywallVC.onSkip = { [weak self] in
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenInitialPaywall)
                self?.start()
            }
            window?.rootViewController = paywallVC
            return
        }
        */

        let isValidSession = UserSession.current.restore()
        // Always check for online session
        if !isValidSession || Auth.auth().currentUser == nil {
            // Якщо сесія не дійсна або користувач не аутентифікований, переходимо на екран входу
            let signInController = SignInController()
            let navigationController = UINavigationController(rootViewController: signInController)
            navigationController.setNavigationBarHidden(true, animated: false)
            window?.rootViewController = navigationController
        } else {
            // Якщо сесія дійсна, переходимо на головний екран додатку
            window?.rootViewController = MainTabBarController()
            runFinanceHistoryBackfillIfNeeded()
        }
    }

    func set(root controller: UIViewController) {
        let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
        controller.view.addSubview(overlayView)
        window?.rootViewController = controller
        runFinanceHistoryBackfillIfNeeded(for: controller)

        UIView.animate(
            withDuration: 0.4, delay: 0, options: .transitionCrossDissolve,
            animations: {
                overlayView.alpha = 0
            },
            completion: { _ in
                overlayView.removeFromSuperview()
            })
    }

    // MARK: - Helper Methods

    private func checkFreshInstall() {
        let key = UserDefaultsKeys.hasRunBefore
        let hasRunBefore = UserDefaults.standard.bool(forKey: key)

        if !hasRunBefore {
            // This is a fresh install (or data cleared).
            // Firebase Auth persists in Keychain, so we must sign out manually to prevent auto-login.
            logger.info("Fresh install detected. Signing out any existing session.")
            do {
                try Auth.auth().signOut()
            } catch {
                logger.error("Failed to sign out on fresh install: \(error)")
            }

            // Also clear demo data manifest if any (though UserDefaults should be empty)
            DemoDataManager.shared.clearManifest()

            // Mark as run
            UserDefaults.standard.set(true, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Appearance Setup

    private func setupAppearance() {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.NavBar.text]
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.NavBar.text]
            navBarAppearance.backgroundColor = UIColor.NavBar.background
            let appearance = UINavigationBar.appearance(whenContainedInInstancesOf: [
                MainNavigationController.self
            ])
            appearance.standardAppearance = navBarAppearance
            appearance.compactAppearance = navBarAppearance
            appearance.scrollEdgeAppearance = navBarAppearance
            // appearance.prefersLargeTitles = false // Not available on proxy
        } else {
            UINavigationBar.appearance().barTintColor = UIColor.NavBar.text
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor.NavBar.text
            ]
            UINavigationBar.appearance().isTranslucent = false
        }

        UINavigationBar.appearance().tintColor = UIColor.NavBar.text

        if #available(iOS 13.4, *) {
            UIDatePicker.appearance().preferredDatePickerStyle = .wheels
        }
    }
    // MARK: - Debug Helper
    private func logAppState() {
        let isPro = IAPManager.shared.isProPlan == true
        let nextPayment = IAPManager.shared.nextPaymentDate
        let hasSeenOnboarding = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.hasSeenOnboarding)
        let theme = SettingsManager.shared.loadTheme()
        let orderMode = SettingsManager.shared.loadOrderEntryMode()
        let hasDemoData = DemoDataManager.shared.isDemoDataPresent

        var logMessage = "\n================ APP STATE ================\n"
        logMessage += "💎 Pro Plan: \(isPro ? "✅ YES" : "❌ NO")\n"
        if let date = nextPayment {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            logMessage += "📅 Next Payment: \(formatter.string(from: date))\n"
        } else {
            logMessage += "📅 Next Payment: N/A\n"
        }
        logMessage += "🎓 Onboarding Seen: \(hasSeenOnboarding ? "YES" : "NO")\n"
        logMessage += "📊 Demo Data Present: \(hasDemoData ? "YES" : "NO")\n"
        logMessage += "🎨 Theme: \(theme)\n"
        logMessage += "📝 Order Mode: \(orderMode == .perOrder ? "Per Order" : "Open Tab")\n"
        logMessage += "===========================================\n"

        logger.info(logMessage)
    }

    private func runFinanceHistoryBackfillIfNeeded(for controller: UIViewController? = nil) {
        let rootController = controller ?? window?.rootViewController
        guard Auth.auth().currentUser != nil else { return }
        guard rootController is MainTabBarController else { return }

        Task {
            do {
                _ = try await FinanceHistoryBackfillService().runIfNeeded()
            } catch {
                logger.error("Finance history backfill failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - OnboardingViewControllerDelegate
extension SceneDelegate: OnboardingViewControllerDelegate {
    func didFinishOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenOnboarding)

        let signInController = SignInController()
        let navigationController = UINavigationController(rootViewController: signInController)
        navigationController.setNavigationBarHidden(true, animated: false)

        set(root: navigationController)
    }
}

extension SceneDelegate {
    private func seedDefaultIncomeTypesIfNeeded() {
        let key = UserDefaultsKeys.firstLaunch
        let seeded = UserDefaults.standard.bool(forKey: key)
        if seeded { return }

        Task { @MainActor in
            let types = await DomainDatabaseService.shared.fetchTypes()
            if !types.isEmpty {
                UserDefaults.standard.set(true, forKey: key)
                UserDefaults.standard.synchronize()
                return
            }
            let names = [
                R.string.global.typeHall(),
                R.string.global.typeTakeaway(),
                R.string.global.typeDelivery(),
            ]
            for name in names {
                let model = TypeModel(id: UUID().uuidString, name: name)
                _ = await DomainDatabaseService.shared.saveType(model: model)
            }
            UserDefaults.standard.set(true, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

// Onboarding types are declared in View Layer/UI/Onboarding/OnboardingManager.swift

// buildDefaultOnboardingRegistry() is declared in View Layer/UI/Onboarding/OnboardingManager.swift

// InstructionsDriver is declared in View Layer/UI/Onboarding/InstructionsDriver.swift
