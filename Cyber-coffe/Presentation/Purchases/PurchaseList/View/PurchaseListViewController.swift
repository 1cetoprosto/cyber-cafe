//
//  PurchaseListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
//import RealmSwift

class PurchaseListViewController: UIViewController {
    var viewModel: PurchaseListViewModelType?
    
    let idPurchasesCell = "idPurchasesCell"
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel = PurchaseListViewModel()
        viewModel?.getPurchases { [weak self] in
            self?.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Purchases"
        
        tableView.register(PurchasesTableViewCell.self, forCellReuseIdentifier: idPurchasesCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(performAdd(param:)))
        setConstraints()
        
    }

    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let purchaseVC = PurchaseDetailsListViewController()
        navigationController?.pushViewController(purchaseVC, animated: true)
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PurchaseListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfRowInSection(for: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idPurchasesCell,
                                                 for: indexPath) as? PurchasesTableViewCell

        guard let tableViewCell = cell,
        let viewModel = viewModel else { return UITableViewCell() }
        
        let cellViewModel = viewModel.cellViewModel(for: indexPath)

        tableViewCell.viewModel = cellViewModel
        
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        viewModel.selectRow(atIndexPath: indexPath)
        var detailViewModel = viewModel.viewModelForSelectedRow()
        detailViewModel?.newModel = false
        
        let purchaseVC = PurchaseDetailsListViewController()
        purchaseVC.viewModel = detailViewModel

        self.navigationController?.pushViewController(purchaseVC, animated: true)
    }
}

// MARK: setConstraints
extension PurchaseListViewController {
    func setConstraints() {

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }
}
