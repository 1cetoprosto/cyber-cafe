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

    // Налаштування кнопки назад без тексту
    navigationItem.backBarButtonItem = UIBarButtonItem(
      title: "", style: .plain, target: nil, action: nil)

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
    let costVC = CostDetailsListViewController()
    // costVC.viewModel = CostDetailsViewModel(cost: CostModel(id: "", date: Date(), name: "", sum: 0))
    // costVC.delegate = self
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

    let costVC = CostDetailsListViewController()
    costVC.viewModel = detailViewModel

    self.navigationController?.pushViewController(costVC, animated: true)
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
