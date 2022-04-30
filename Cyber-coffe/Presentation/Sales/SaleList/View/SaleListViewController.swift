//
//  SaleListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
import RealmSwift

class SaleListViewController: UIViewController {

    private var viewModel: SaleListViewModelType?

    let idSalesCell = "idSalesCell"
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel = SaleListViewModel()
        viewModel?.getSales { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Sales"
        
        tableView.register(SalesTableViewCell.self, forCellReuseIdentifier: idSalesCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Кнопка зправа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(performAdd(param:)))
        
        setConstraints()
        
//        viewModel = SaleListViewModel()
//        viewModel?.getSales { [weak self] in
//            self?.tableView.reloadData()
//        }
    }

    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let saleVC = SaleDetailsViewController()
        navigationController?.pushViewController(saleVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SaleListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }
        return viewModel.numberOfRowInSection(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSalesCell, for: indexPath) as? SalesTableViewCell
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
        
        let saleVC = SaleDetailsViewController()
        saleVC.viewModel = detailViewModel
        
        self.navigationController?.pushViewController(saleVC, animated: true)
    }

//    func tableView(_ tableView: UITableView,
//                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let editingRow = sales[indexPath.row]
//
//        let dateStart = Calendar.current.startOfDay(for: editingRow.salesDate)
//        let dateEnd: Date = {
//            let components = DateComponents(day: 1, second: -1)
//            return Calendar.current.date(byAdding: components, to: dateStart)!
//        }()
//        
//        let predicateDate = NSPredicate(format: "saleDate BETWEEN %@", [dateStart, dateEnd])
//        salesGoods = localRealm.objects(SaleGoodModel.self).filter(predicateDate)
//
//        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
//            DatabaseManager.shared.deleteSalesModel(model: editingRow)
//
//            for saleGood in self.salesGoods {
//                DatabaseManager.shared.deleteSaleGoodModel(model: saleGood)
//            }
//
//            self.configure()
//            
//            tableView.reloadData()
//        }
//
//        return UISwipeActionsConfiguration(actions: [deleteAction])
//    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            viewModel.deleteSaleModel(atIndexPath: indexPath)
            
            viewModel.getSales { [weak self] in
                self?.tableView.reloadData()
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: Constraints
extension SaleListViewController {
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
