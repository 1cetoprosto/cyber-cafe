//
//  TypesListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation
import UIKit
import RealmSwift

class IncomeTypesListViewController: UIViewController {

    var incomeTypes = [IncomeTypeModel]()
    
    let idTypesOfDonationCell = "idTypesOfDonationCell"
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
        //tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Income types"
        
        tableView.register(TypeTableViewCell.self, forCellReuseIdentifier: idTypesOfDonationCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(performAdd(param:)))
        
        setConstraints()
    }

    func configure() {
        DomainDatabaseService.shared.fetchIncomeTypes { incomeTypes in
            self.incomeTypes = incomeTypes
            self.tableView.reloadData()
        }
    }
    
    func setConstraints() {
        
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

    }
    
    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let typeVC = IncomeTypeDetailsViewController(incomeType: IncomeTypeModel(id: "", name: ""))
        navigationController?.pushViewController(typeVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension IncomeTypesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incomeTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idTypesOfDonationCell, for: indexPath) as! TypeTableViewCell
        cell.configure(incomeType: incomeTypes[indexPath.row], indexPath: indexPath)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = incomeTypes[indexPath.row]
        
        let typeVC = IncomeTypeDetailsViewController(incomeType: model)
//        typeVC.typesModel = model
//        typeVC.newModel = false
        //typeVC.incomeType = model
        navigationController?.pushViewController(typeVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = incomeTypes[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            
            DomainDatabaseService.shared.deleteIncomeType(model: model) { success in
                if success {
                    print("Income type deleted successfully")
                    self.configure()
                    
                    tableView.reloadData()
                } else {
                    print("Failed to delete income type")
                }
            }
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
