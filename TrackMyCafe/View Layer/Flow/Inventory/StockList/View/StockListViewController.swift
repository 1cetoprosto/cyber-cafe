//
//  StockListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import UIKit
import TinyConstraints

class StockListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: StockListViewModelProtocol
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(StockItemCell.self, forCellReuseIdentifier: "StockItemCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
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
        viewModel.fetchStock()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Inventory"
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
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAdjustmentAlert(for ingredient: IngredientModel) {
        let alert = UIAlertController(
            title: "Adjust Stock",
            message: "Enter new quantity for \(ingredient.name)",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.keyboardType = .decimalPad
            textField.text = String(format: "%.2f", ingredient.stockQuantity)
            textField.placeholder = "Quantity"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text,
                  let newQuantity = Double(text.replacingOccurrences(of: ",", with: ".")) else {
                return
            }
            self?.viewModel.updateStock(for: ingredient, newQuantity: newQuantity)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StockItemCell", for: indexPath) as? StockItemCell else {
            return UITableViewCell()
        }
        let ingredient = viewModel.ingredients[indexPath.row]
        cell.configure(with: ingredient)
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let adjustAction = UIContextualAction(style: .normal, title: "Adjust") { [weak self] _, _, completion in
            guard let self = self else { return }
            let ingredient = self.viewModel.ingredients[indexPath.row]
            self.showAdjustmentAlert(for: ingredient)
            completion(true)
        }
        adjustAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [adjustAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let ingredient = viewModel.ingredients[indexPath.row]
        showAdjustmentAlert(for: ingredient)
    }
}
