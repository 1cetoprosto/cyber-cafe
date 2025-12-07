//
//  CostListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit

class CostListViewController: UIViewController {
  private var viewModel: CostListViewModelType?

  let tableView: UITableView = {
    let tableView = UITableView()

    tableView.register(
      CostsTableViewCell.self, forCellReuseIdentifier: CostsTableViewCell.identifier)
    tableView.backgroundColor = UIColor.Main.background
    tableView.separatorStyle = .none
    tableView.translatesAutoresizingMaskIntoConstraints = false

    return tableView
  }()

  private lazy var addButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "plus"), for: .normal)
    button.addTarget(self, action: #selector(performAdd(param:)), for: .touchUpInside)
    button.accessibilityIdentifier = "navBarAddCost"
    return button
  }()

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    viewModel = CostListViewModel()
    viewModel?.getCosts { [weak self] in
      self?.tableView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.Main.background
    title = R.string.global.costs()

    tableView.dataSource = self
    tableView.delegate = self

    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    setConstraints()

  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    OnboardingManager.shared.startIfNeeded(for: .costs, on: self)
  }

  // MARK: - Method
  @objc func performAdd(param: UIBarButtonItem) {
    let vm = CostDetailsViewModel(
      cost: CostModel(id: "", date: Date(), name: "", sum: 0.0),
      dataService: DomainCostDataService()
    )
    let costVC = CostDetailsListViewController(viewModel: vm)
    navigationController?.pushViewController(costVC, animated: true)
  }

}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CostListViewController: UITableViewDelegate, UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return viewModel?.numberOfSections() ?? 0
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return viewModel?.titleForHeaderInSection(for: section)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel?.numberOfRowInSection(for: section) ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(
        withIdentifier: CostsTableViewCell.identifier,
        for: indexPath) as? CostsTableViewCell

    guard let tableViewCell = cell,
      let viewModel = viewModel
    else { return UITableViewCell() }

    let cellViewModel = viewModel.cellViewModel(for: indexPath)

    tableViewCell.viewModel = cellViewModel

    return tableViewCell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let viewModel = viewModel else { return }
    viewModel.selectRow(atIndexPath: indexPath)
    let detailViewModel = viewModel.viewModelForSelectedRow()

    guard let vm = detailViewModel else { return }
    let costVC = CostDetailsListViewController(viewModel: vm)
    self.navigationController?.pushViewController(costVC, animated: true)
  }

  func tableView(
    _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
  ) {
    guard let header = view as? UITableViewHeaderFooterView else { return }
    header.textLabel?.font = Typography.footnote
    header.textLabel?.textColor = UIColor.Main.text
    if #available(iOS 11.0, *) { header.textLabel?.adjustsFontForContentSizeCategory = true }
  }

  func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    guard let viewModel = viewModel else { return nil }
    let deleteAction = UIContextualAction(style: .destructive, title: R.string.global.delete()) {
      _, _, _ in
      viewModel.deleteCostModel(atIndexPath: indexPath)

      viewModel.getCosts { [weak self] in
        self?.tableView.reloadData()
      }
    }

    return UISwipeActionsConfiguration(actions: [deleteAction])
  }
}

// // MARK: - CostDetailsListViewControllerDelegate
// extension CostListViewController: CostDetailsListViewControllerDelegate {
//   func didSaveCost(_ cost: CostDetailsViewModelType) {
//     // Оновлюємо дані після збереження
//     viewModel?.getCosts { [weak self] in
//       DispatchQueue.main.async {
//         self?.tableView.reloadData()
//       }
//     }
//   }
// }

// MARK: setConstraints
extension CostListViewController {
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
