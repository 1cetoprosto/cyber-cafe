//
//  StockListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import TinyConstraints
import UIKit

class StockListViewController: UIViewController, ProGated {

    // MARK: - Properties

    private let viewModel: StockListViewModelProtocol

    private lazy var tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.register(StockItemCell.self, forCellReuseIdentifier: "StockItemCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init

    init(viewModel: StockListViewModelProtocol = StockListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        // viewModel.fetchStock() // Moved to viewWillAppear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchStock()
    }

    // MARK: - Setup

    private func setupUI() {
        // title = R.string.global.inventoryTitle() // Title managed by parent tab controller
        view.backgroundColor = UIColor.Main.background

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        tableView.edgesToSuperview()
        activityIndicator.centerInSuperview()

        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func bindViewModel() {
        var vm = viewModel

        vm.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.tableView.refreshControl?.endRefreshing()
            }
        }

        vm.isLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
        }

        vm.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showError(message: errorMessage)
            }
        }
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.fetchStock()
    }

    private func showError(message: String) {
        PopupFactory.showPopup(
            title: R.string.global.error(),
            description: message,
            buttonAction: nil
        )
    }

    private func showAdjustmentAlert(for ingredient: IngredientModel) {
        let description = String(
            format: R.string.global.inventoryEnterActualQty(
                ingredient.stockQuantity, ingredient.name),
            ingredient.stockQuantity,
            ingredient.name
        )

        let fields: [InputFieldConfig] = [
            InputFieldConfig(
                placeholder: R.string.global.inventoryActualQtyPlaceholder(),
                keyboardType: .decimalPad
            ),
            InputFieldConfig(
                placeholder: R.string.global.inventoryReasonPlaceholder(),
                keyboardType: .default
            ),
        ]

        PopupFactory.showInputPopup(
            title: R.string.global.inventoryAdjustStock(),
            description: description,
            fields: fields
        ) { [weak self] values in
            guard let self else { return }
            let actualText = values.first ?? ""
            let reasonText = values.count > 1 ? values[1] : ""

            let normalizedActualText = actualText.replacingOccurrences(of: ",", with: ".")
            guard let actualQty = Double(normalizedActualText) else {
                self.showError(message: R.string.global.invalidQuantity())
                return
            }

            let delta = actualQty - ingredient.stockQuantity
            guard delta != 0 else {
                self.showError(message: R.string.global.invalidQuantity())
                return
            }

            let trimmedReason = reasonText.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines)
            guard !trimmedReason.isEmpty else {
                let field = R.string.global.inventoryReason()
                self.showError(message: R.string.global.fieldRequired(field))
                return
            }

            self.viewModel.applyAdjustment(for: ingredient, delta: delta, reason: trimmedReason)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension StockListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.ingredients.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "StockItemCell", for: indexPath) as? StockItemCell
        else {
            return UITableViewCell()
        }
        let ingredient = viewModel.ingredients[indexPath.row]
        cell.configure(with: ingredient)
        return cell
    }

    func tableView(
        _ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let adjustAction = UIContextualAction(
            style: .normal, title: R.string.global.inventoryAdjustStock()
        ) { [weak self] _, _, completion in
            guard let self = self else { return }

            self.checkProOrShowPaywall(
                onSuccess: { [weak self] in
                    guard let self else { return }
                    let ingredient = self.viewModel.ingredients[indexPath.row]
                    self.showAdjustmentAlert(for: ingredient)
                    completion(true)
                },
                onDenied: {
                    completion(false)
                }
            )
        }
        adjustAction.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [adjustAction])
    }
}
