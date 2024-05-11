//
//  TypesListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation
import UIKit
import RealmSwift

class TypesListViewController: UIViewController {

    let localRealm = try! Realm()
    var typesArray: Results<TypeOfDonationModel>!
    
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
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Types of donation"
        
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
        typesArray = localRealm.objects(TypeOfDonationModel.self).sorted(byKeyPath: "type")
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
        let typeVC = TypeDetailsViewController()
        navigationController?.pushViewController(typeVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TypesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typesArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idTypesOfDonationCell, for: indexPath) as! TypeTableViewCell
        cell.configure(typeOfDonation: typesArray[indexPath.row], indexPath: indexPath)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = typesArray[indexPath.row]
        
        let typeVC = TypeDetailsViewController()
        typeVC.typesModel = model
        typeVC.newModel = false
        typeVC.type = model.type
        navigationController?.pushViewController(typeVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = typesArray[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            let itemDeleted = FIRFirestoreService.shared.delete(collection: "typesOfDonation", documentId: model.id)
            if itemDeleted {
                DatabaseManager.shared.delete(model: model)
                
                self.configure()
                
                tableView.reloadData()
            } else {
                //TODO: add in table for delete later, when wiil be sinhronize
                
            }
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
