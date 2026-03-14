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
        let tableView = UITableView()
        tableView.register(StockItemCell.self, forCellReuseIdentifier: "StockItemCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
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

        tableView.backgroundColor = UIColor.Main.background

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
        let alert = UIAlertController(
            title: R.string.global.inventoryAdjustStock(),
            message: String(
                format: R.string.global.inventoryEnterDelta(ingredient.name), ingredient.name),
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.placeholder = R.string.global.inventoryDeltaPlaceholder()
        }

        alert.addTextField { textField in
            textField.keyboardType = .default
            textField.placeholder = R.string.global.inventoryReasonPlaceholder()
        }

        let saveAction = UIAlertAction(title: R.string.global.save(), style: .default) { [weak self] _ in
            guard let self else { return }
            let deltaText = alert.textFields?.first?.text ?? ""
            let reasonText = (alert.textFields?.count ?? 0) > 1 ? (alert.textFields?[1].text ?? "") : ""

            let normalizedDeltaText = deltaText.replacingOccurrences(of: ",", with: ".")
            guard let delta = Double(normalizedDeltaText), delta != 0 else {
                self.showError(message: R.string.global.invalidQuantity())
                return
            }

            let trimmedReason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedReason.isEmpty else {
                let field = R.string.global.inventoryReason()
                self.showError(message: R.string.global.fieldRequired(field))
                return
            }

            self.viewModel.applyAdjustment(for: ingredient, delta: delta, reason: trimmedReason)
        }

        let cancelAction = UIAlertAction(title: R.string.global.cancel(), style: .cancel)

        alert.addAction(cancelAction)
        alert.addAction(saveAction)

        present(alert, animated: true)
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

            if !self.checkProOrShowPaywall() {
                completion(false)
                return
            }

            let ingredient = self.viewModel.ingredients[indexPath.row]
            self.showAdjustmentAlert(for: ingredient)
            completion(true)
        }
        adjustAction.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [adjustAction])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let ingredient = self.viewModel.ingredients[indexPath.row]
            self.showAdjustmentAlert(for: ingredient)
        }
    }
}
