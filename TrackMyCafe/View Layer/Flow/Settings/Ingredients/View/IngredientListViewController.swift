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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(IngredientTableViewCell.self, forCellReuseIdentifier: IngredientTableViewCell.identifier)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        return tableView
    }()

    // MARK: - Init
    
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
        let createVC = CreateIngredientViewController(viewModel: viewModel)
        present(createVC, animated: true)
    }
}

extension IngredientListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.ingredients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: IngredientTableViewCell.identifier, for: indexPath)
                as? IngredientTableViewCell
        else {
            return UITableViewCell()
        }

        let ingredient = viewModel.ingredients[indexPath.row]
        cell.configure(with: ingredient)

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
