//
//  CostsTabViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import TinyConstraints
import UIKit

class CostsTabViewController: UIViewController {

    // MARK: - Properties

    private let segmentedControl: UISegmentedControl = {
        let items = ["Inventory", "Costs"]  // Localize later
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let containerView = UIView()

    // Child View Controllers
    private lazy var inventoryContainerVC = InventoryContainerViewController()
    private lazy var costListVC = CostListViewController()

    private var currentChild: UIViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayChild(inventoryContainerVC)  // Default
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Costs & Inventory"
        view.backgroundColor = UIColor.Main.background

        // Setup Segmented Control in Navigation Title View or below Navigation Bar
        // Placing it below navigation bar for better accessibility and standard iOS look

        view.addSubview(segmentedControl)
        view.addSubview(containerView)

        segmentedControl.topToSuperview(offset: 8, usingSafeArea: true)
        segmentedControl.leadingToSuperview(offset: 16)
        segmentedControl.trailingToSuperview(offset: 16)

        containerView.topToBottom(of: segmentedControl, offset: 8)
        containerView.leadingToSuperview()
        containerView.trailingToSuperview()
        containerView.bottomToSuperview()

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        let newChild: UIViewController

        switch segmentedControl.selectedSegmentIndex {
        case 0:
            newChild = inventoryContainerVC
        case 1:
            newChild = costListVC
        default:
            return
        }

        if currentChild == newChild { return }
        displayChild(newChild)
    }

    private func displayChild(_ child: UIViewController) {
        // Remove current child
        if let current = currentChild {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // Add new child
        addChild(child)
        containerView.addSubview(child.view)
        child.view.edgesToSuperview()
        child.didMove(toParent: self)

        currentChild = child

        // Update Navigation Item buttons based on child
        updateNavigationItems(for: child)
    }

    private func updateNavigationItems(for child: UIViewController) {
        // Proxy the navigation items from the child to this container
        navigationItem.rightBarButtonItems = child.navigationItem.rightBarButtonItems
        navigationItem.leftBarButtonItems = child.navigationItem.leftBarButtonItems
        title = child.title ?? "Costs & Inventory"
    }
}
