//
//  ViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 02.11.2021.
//

import FirebaseAuth
import SVProgressHUD
import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
        applyTabBarAppearance()
        navigationController?.view.backgroundColor = UIColor.NavBar.background
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAndSeedDemoDataIfNeeded()
    }

    private func checkAndSeedDemoDataIfNeeded() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let hasCheckedDemoDataKey = "hasCheckedDemoData_\(userId)"

        let hasCheckedDemoData = UserDefaults.standard.bool(forKey: hasCheckedDemoDataKey)
        guard !hasCheckedDemoData else { return }

        // Mark as checked so we don't check again on subsequent launches
        UserDefaults.standard.set(true, forKey: hasCheckedDemoDataKey)

        // Check if DB is empty (simple check: if no products, likely empty)
        DomainDatabaseService.shared.fetchProductsPrice { [weak self] products in
            guard products.isEmpty else { return }

            DispatchQueue.main.async {
                self?.seedDemoData()
            }
        }
    }

    private func seedDemoData() {
        SVProgressHUD.show(
            withStatus: R.string.global.preparingDemoData())
        Task {
            await DomainDatabaseService.shared.seedUserDemoData()
            await MainActor.run {
                SVProgressHUD.dismiss()
                SVProgressHUD.showSuccess(withStatus: R.string.global.success())
                // Notify other controllers to reload data
                NotificationCenter.default.post(
                    name: NSNotification.Name("DataDidUpdate"), object: nil)

                // If the current selected view controller responds to reloading, we might want to trigger it manually
                // But NotificationCenter should handle it if observers are set up.
                // Since this happens on first launch, viewControllers might already be loaded.
                // We can iterate and reload if they have a reload method, but notification is cleaner.
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Handle system theme changes only if user has selected system appearance
        if Theme.currentSelection.appearance == .system {
            Theme.followSystemTheme()

            // Update UI colors for current interface
            updateInterfaceColors()
        }
    }

    private func updateInterfaceColors() {
        // Update tab bar colors
        applyTabBarAppearance()
        navigationController?.view.backgroundColor = UIColor.NavBar.background

        // Update all child navigation controllers
        viewControllers?.forEach { viewController in
            if let navController = viewController as? UINavigationController {
                navController.view.backgroundColor = UIColor.NavBar.background
            }
        }
    }

    // Configure UITabBarAppearance to ensure good contrast for selected/unselected icons
    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.current.primaryBackground

        // Unified selected/unselected icon colors across palettes
        let selectedColor: UIColor = Theme.current.tabBarTint

        // Unselected color sourced from theme for consistency across palettes
        let unselectedColor = Theme.current.tabBarUnselectedTint

        // Apply to stacked layout
        let stacked = appearance.stackedLayoutAppearance
        stacked.selected.iconColor = selectedColor
        stacked.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: Typography.footnote,
        ]
        stacked.normal.iconColor = unselectedColor
        stacked.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: Typography.footnote,
        ]

        // Apply to inline layout
        let inline = appearance.inlineLayoutAppearance
        inline.selected.iconColor = selectedColor
        inline.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: Typography.footnote,
        ]
        inline.normal.iconColor = unselectedColor
        inline.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: Typography.footnote,
        ]

        // Apply to compact inline layout
        let compact = appearance.compactInlineLayoutAppearance
        compact.selected.iconColor = selectedColor
        compact.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: Typography.footnote,
        ]
        compact.normal.iconColor = unselectedColor
        compact.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: Typography.footnote,
        ]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        // Keep legacy properties in sync (used by some UIKit APIs)
        tabBar.tintColor = selectedColor
        tabBar.unselectedItemTintColor = unselectedColor
    }

    func setupTabBar() {
        // Tab 1: Home (Dashboard)
        let homeViewController = createNavController(
            viewController: HomeViewController(),
            itemName: R.string.global.home(),
            itemImage: SystemImages.home)

        // Tab 2: Income (Orders)
        let ordersViewController = createNavController(
            viewController: OrderListViewController(),
            itemName: R.string.global.income(),  // Or "Orders" / "POS"
            itemImage: SystemImages.mug)

        // Tab 3: Costs & Inventory (New Container)
        let costsTabViewController = createNavController(
            viewController: CostsTabViewController(),
            itemName: R.string.global.costs(),  // Should ideally be "Costs & Inventory"
            itemImage: SystemImages.bag)

        // Tab 4: Reports (Placeholder for now, using existing logic or empty)
        // For now, let's skip Reports tab creation until implemented, or use a placeholder
        // Using PurchaseListViewController as a temporary placeholder if needed,
        // but since Purchases are now in Tab 3, we can leave Tab 4 for Reports later.
        // For MVP 2.0 structure, let's keep 5 tabs if possible, or 4.
        // Let's create a temporary Reports placeholder.
//        let reportsViewController = createNavController(
//            viewController: UIViewController(),  // Placeholder
//            itemName: R.string.global.reportsTitle(),
//            itemImage: "chart.bar")  // SystemImages.chartBar if exists, or string
//        reportsViewController.viewControllers.first?.view.backgroundColor = .systemBackground
//        reportsViewController.viewControllers.first?.title = R.string.global.reportsTitle()

        // Tab 5: Settings
        let settingsViewController = createNavController(
            viewController: SettingListViewController(),
            itemName: R.string.global.menuSettings(),
            itemImage: SystemImages.gearshape)

        // Update: Removed separate Purchases tab (now in Tab 3)
        // Added Reports placeholder
        viewControllers = [
            homeViewController,
            ordersViewController,
            costsTabViewController,
            // reportsViewController,
            settingsViewController,
        ]
    }

    func createNavController(
        viewController: UIViewController,
        itemName: String,
        itemImage: String
    ) -> UINavigationController {
        viewController.title = itemName
        let item = UITabBarItem(title: itemName, image: UIImage(systemName: itemImage), tag: 0)
        item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
        item.imageInsets = .zero

        let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem = item
        navController.view.backgroundColor = UIColor.NavBar.background

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.NavBar.background
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.NavBar.text,
            .font: Typography.title3DemiBold,
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.NavBar.text,
            .font: Typography.title2DemiBold,
        ]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.NavBar.text,
            .font: Typography.body,
        ]
        buttonAppearance.highlighted.titleTextAttributes = [
            .foregroundColor: UIColor.NavBar.text,
            .font: Typography.bodyMedium,
        ]
        navAppearance.buttonAppearance = buttonAppearance
        navAppearance.doneButtonAppearance = buttonAppearance
        navAppearance.backButtonAppearance = buttonAppearance

        navController.navigationBar.standardAppearance = navAppearance
        if #available(iOS 15.0, *) {
            navController.navigationBar.scrollEdgeAppearance = navAppearance
        }
        navController.navigationBar.prefersLargeTitles = true

        return navController
    }

}
