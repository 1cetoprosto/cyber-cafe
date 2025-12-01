//
//  OrderListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit

class OrderListViewController: UIViewController {
  private var viewModel: OrderListViewModelType?

  let tableView: UITableView = {
    let tableView = UITableView()

    tableView.register(
      OrdersTableViewCell.self, forCellReuseIdentifier: OrdersTableViewCell.identifier)
    tableView.backgroundColor = UIColor.Main.background
    tableView.separatorStyle = .none
    tableView.translatesAutoresizingMaskIntoConstraints = false

    return tableView
  }()

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    fetchOrdersData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.Main.background
    title = R.string.global.orders()

    tableView.dataSource = self
    tableView.delegate = self

    // Button right
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(performAdd(param:)))

    setConstraints()
  }

  // MARK: - Method
  @objc func performAdd(param: UIBarButtonItem) {
    let orderVC = OrderDetailsViewController()
    navigationController?.pushViewController(orderVC, animated: true)
  }

  private func fetchOrdersData() {
    viewModel = OrderListViewModel()
    viewModel?.getOrders { [weak self] in
      self?.tableView.reloadData()
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
    let deleteAction = UIContextualAction(style: .destructive, title: R.string.global.delete()) {
      _, _, _ in
      viewModel.deleteOrderModel(atIndexPath: indexPath)

      viewModel.getOrders { [weak self] in
        self?.tableView.reloadData()
      }
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

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
    ])
  }
}
