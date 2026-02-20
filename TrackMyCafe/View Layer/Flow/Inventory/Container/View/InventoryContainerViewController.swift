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
        let items = ["Stock", "Purchases", "Audit"]  // Localize later
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let containerView = UIView()

    // Child View Controllers
    private lazy var stockListVC = StockListViewController()

    // PurchaseListViewController requires a ViewModel
    private lazy var purchaseListVC: PurchaseListViewController = {
        let vm = PurchaseListViewModel()
        return PurchaseListViewController(viewModel: vm)
    }()

    private lazy var auditVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemGroupedBackground
        let label = UILabel()
        label.text = "Inventory Audit (Coming Soon)"
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
        // Start with Stock List
        displayChild(stockListVC)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background

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
    }
}
