//
//  IngredientListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 29.01.2026.
//

import UIKit
import TinyConstraints

class IngredientListViewController: UIViewController {
    
    private let viewModel: IngredientListViewModelType
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    init(viewModel: IngredientListViewModelType = IngredientListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        Task {
            await viewModel.fetchIngredients()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = viewModel.title
        
        view.addSubview(tableView)
        tableView.edgesToSuperview()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addIngredientAction))
    }
    
    private func setupBindings() {
        var vm = viewModel
        vm.onIngredientsUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    @objc private func addIngredientAction() {
        let alert = UIAlertController(title: R.string.global.addIngredient(), message: nil, preferredStyle: .alert)
        
        alert.addTextField { $0.placeholder = R.string.global.productName() }
        alert.addTextField { $0.placeholder = R.string.global.price(); $0.keyboardType = .decimalPad }
        alert.addTextField { $0.placeholder = R.string.global.quantity(); $0.keyboardType = .decimalPad }
        
        alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel))
        alert.addAction(UIAlertAction(title: R.string.global.add(), style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let costText = alert.textFields?[1].text, let cost = Double(costText.replacingOccurrences(of: ",", with: ".")),
                  let stockText = alert.textFields?[2].text, let stock = Double(stockText.replacingOccurrences(of: ",", with: "."))
            else { return }
            
            Task {
                await self?.viewModel.createIngredient(name: name, cost: cost, stock: stock, unit: .kg) // Defaulting to kg for simplicity
            }
        })
        
        present(alert, animated: true)
    }
}

extension IngredientListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.ingredients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let ingredient = viewModel.ingredients[indexPath.row]
        cell.textLabel?.text = "\(ingredient.name) (\(ingredient.stockQuantity) \(ingredient.unit.rawValue)) - \(ingredient.averageCost)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Task {
                await viewModel.deleteIngredient(at: indexPath.row)
            }
        }
    }
}
