//
//  OrderListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
import TinyConstraints

class OrderListViewController: UIViewController, Loggable, ProGated {
    private var viewModel: OrderListViewModelType?

    let tableView: UITableView = {
        let tableView = UITableView()

        tableView.register(
            OrdersTableViewCell.self, forCellReuseIdentifier: OrdersTableViewCell.identifier)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        // tableView.translatesAutoresizingMaskIntoConstraints = false // Not needed with TinyConstraints

        return tableView
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(performAdd), for: .touchUpInside)
        button.accessibilityIdentifier = "navBarAddOrder"
        return button
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchOrdersData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        // title = R.string.global.orders() // Title managed by parent tab controller

        tableView.dataSource = self
        tableView.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)

        setConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        OnboardingManager.shared.startIfNeeded(for: .orders, on: self)
    }

    // MARK: - Method
    @objc private func performAdd() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let mode = SettingsManager.shared.loadOrderEntryMode()
            if UIDevice.isIpad, traitCollection.horizontalSizeClass == .regular, mode == .perOrder {
                let split = OrderSplitContainerViewController()
                split.hidesBottomBarWhenPushed = true
                if let nav = self.navigationController {
                    nav.pushViewController(split, animated: true)
                } else {
                    split.modalPresentationStyle = .fullScreen
                    self.present(split, animated: true)
                }
            } else {
                let orderVC = OrderDetailsViewController()
                if let nav = self.navigationController {
                    nav.pushViewController(orderVC, animated: true)
                } else {
                    let nav = UINavigationController(rootViewController: orderVC)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            }
        }
    }

    private func fetchOrdersData() {
        viewModel = OrderListViewModel()
        viewModel?.getOrders { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension OrderListViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.numberOfSections() ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel?.titleForHeaderInSection(for: section)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }
        return viewModel.numberOfRowInSection(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
        tableView.dequeueReusableCell(withIdentifier: OrdersTableViewCell.identifier, for: indexPath)
        as? OrdersTableViewCell
        guard let tableViewCell = cell,
              let viewModel = viewModel
        else { return UITableViewCell() }

        let cellViewModel = viewModel.cellViewModel(for: indexPath)

        tableViewCell.viewModel = cellViewModel

        return tableViewCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        viewModel.selectRow(atIndexPath: indexPath)
        var detailViewModel = viewModel.viewModelForSelectedRow()
        detailViewModel?.isNewModel = false

        let orderVC = OrderDetailsViewController()
        orderVC.viewModel = detailViewModel

        self.navigationController?.pushViewController(orderVC, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: R.string.global.delete()) { [weak self] _, _, completion in
            guard let self = self else { return }

            if !self.checkProOrShowPaywall() {
                completion(false) // Cancel deletion visual
                // Ideally, we should reload row to close swipe, but completion(false) might be enough
                return
            }

            viewModel.deleteOrderModel(atIndexPath: indexPath)

            viewModel.getOrders { [weak self] in
                self?.tableView.reloadData()
            }
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Typography.footnote
        header.textLabel?.textColor = UIColor.Main.text
        if #available(iOS 11.0, *) { header.textLabel?.adjustsFontForContentSizeCategory = true }
    }
}

// MARK: Constraints
extension OrderListViewController {
    func setConstraints() {
        view.addSubview(tableView)
        tableView.edgesToSuperview(
            insets: .init(top: 10, left: 10, bottom: 0, right: 10),
            usingSafeArea: true
        )
    }
}
