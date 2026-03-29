//
//  CostListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit

class CostListViewController: UIViewController, Loggable, ProGated {
    private var viewModel: CostListViewModelType?

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)

        tableView.register(
            CostsTableViewCell.self, forCellReuseIdentifier: CostsTableViewCell.identifier)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.TableView.separator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
    button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(performAdd(param:)), for: .touchUpInside)
        button.accessibilityIdentifier = "navBarAddCost"
        return button
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel = CostListViewModel()
        viewModel?.getCosts { [weak self] in
      DispatchQueue.main.async {
        self?.tableView.reloadData()
      }
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
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let vm = CostDetailsViewModel(
                cost: OpexExpenseModel(
                    id: "", date: Date(), categoryId: "General", amount: 0.0, note: ""
                ),
                dataService: DomainCostDataService()
            )
            let costVC = CostDetailsListViewController(viewModel: vm)
            self.navigationController?.pushViewController(costVC, animated: true)
        }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

        let deleteAction = UIContextualAction(style: .destructive, title: R.string.global.delete()) { [weak self] _, _, completion in
            guard let self else { return }

            self.checkProOrShowPaywall(
                onSuccess: { [weak self] in
                    guard let self else { return }
                    viewModel.deleteCostModel(atIndexPath: indexPath)

                    viewModel.getCosts { [weak self] in
                        self?.tableView.reloadData()
                    }
                    completion(true)
                },
                onDenied: {
                    completion(false)
                }
            )
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
        tableView.edgesToSuperview(usingSafeArea: true)
    }
}
