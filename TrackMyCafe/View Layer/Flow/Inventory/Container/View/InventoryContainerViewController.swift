//
//  InventoryContainerViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import TinyConstraints
import UIKit

class InventoryContainerViewController: UIViewController {

    // MARK: - Properties

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Stock", "Purchases", "Audit"])  // Will be updated in setupUI
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let containerView = UIView()

    // Child View Controllers
    private lazy var stockListVC: UIViewController = {
        let vm = StockListViewModel()
        return StockListViewController(viewModel: vm)
    }()

    private lazy var purchaseListVC: UIViewController = {
        // Initialize Purchase List
        let vm = PurchaseListViewModel()
        return PurchaseListViewController(viewModel: vm)
    }()

    private lazy var auditVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemGroupedBackground
        let label = UILabel()
        label.text = R.string.global.inventoryAuditComingSoon()
        label.textColor = .label
        vc.view.addSubview(label)
        label.centerInSuperview()
        return vc
    }()

    private var currentChild: UIViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayChild(stockListVC)  // Default
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background

        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(
            withTitle: R.string.global.inventorySegmentStock(), at: 0, animated: false)
        segmentedControl.insertSegment(
            withTitle: R.string.global.inventorySegmentPurchases(), at: 1, animated: false)
        segmentedControl.insertSegment(
            withTitle: R.string.global.inventorySegmentAudit(), at: 2, animated: false)
        segmentedControl.selectedSegmentIndex = 0

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
            newChild = stockListVC
        case 1:
            newChild = purchaseListVC
        case 2:
            newChild = auditVC
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

        // Update Navigation Items
        updateNavigationItems(for: child)
    }

    private func updateNavigationItems(for child: UIViewController) {
        // Since we are inside CostsTabViewController (which also has a container),
        // we need to push items up to parent's navigation item if possible,
        // or just set them on self.navigationItem so parent can read them.

        navigationItem.rightBarButtonItems = child.navigationItem.rightBarButtonItems
        navigationItem.leftBarButtonItems = child.navigationItem.leftBarButtonItems

        // Notify parent (CostsTabViewController) to update its navigation items
        // This is a bit hacky but works for nested containers
        if let parent = parent as? CostsTabViewController {
            parent.updateNavigationItems(for: self)
        }
    }
}
