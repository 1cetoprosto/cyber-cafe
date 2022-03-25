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

    let localRealm = try! Realm()
    var sales: Results<SalesModel>!
    
    var salesGoods: Results<SaleGoodModel>!

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
        configure()
        tableView.reloadData()
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
        
        viewModel = SaleListViewModel()
        viewModel?.getSales { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - Method
    func configure() {
        sales = localRealm.objects(SalesModel.self).sorted(byKeyPath: "salesDate")
        tableView.reloadData()
    }
    
    @objc func performAdd(param: UIBarButtonItem) {
        let saleVC = SaleDetailsViewController()
        navigationController?.pushViewController(saleVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SaleListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSalesCell, for: indexPath) as! SalesTableViewCell
        cell.configure(sale: sales[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let saleVC = SaleDetailsViewController()
        
        let model = sales[indexPath.row]
        saleVC.salesDateModel = model
        saleVC.forDate = model.salesDate
        saleVC.salesCash = model.salesCash
        saleVC.salesSum = model.salesSum
        saleVC.newModel = false
        
        self.navigationController?.pushViewController(saleVC, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editingRow = sales[indexPath.row]

        let dateStart = Calendar.current.startOfDay(for: editingRow.salesDate)
        let dateEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: dateStart)!
        }()
        
        let predicateDate = NSPredicate(format: "saleDate BETWEEN %@", [dateStart, dateEnd])
        salesGoods = localRealm.objects(SaleGoodModel.self).filter(predicateDate)

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            DatabaseManager.shared.deleteSalesModel(model: editingRow)

            for saleGood in self.salesGoods {
                DatabaseManager.shared.deleteSaleGoodModel(model: saleGood)
            }

            self.configure()
            
            tableView.reloadData()
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
