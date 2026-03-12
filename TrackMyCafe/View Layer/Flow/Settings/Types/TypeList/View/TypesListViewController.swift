//
//  TypesListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import Foundation
import RealmSwift
import TinyConstraints
import UIKit

class TypesListViewController: UIViewController, Loggable {

    var types = [TypeModel]()

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine

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
        title = R.string.global.types()

        tableView.register(
            TypeTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.typesCell)
        tableView.dataSource = self
        tableView.delegate = self

        // Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(performAdd(param:)))

        setConstraints()
    }

    func configure() {
        DomainDatabaseService.shared.fetchTypes { types in
            self.types = types
            self.tableView.reloadData()
        }
    }

    func setConstraints() {
        view.addSubview(tableView)

        tableView.edgesToSuperview()
    }

    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let typeVC = TypeDetailsViewController(type: TypeModel(id: "", name: ""))
        navigationController?.pushViewController(typeVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TypesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.typesCell, for: indexPath)
            as! TypeTableViewCell
        cell.configure(type: types[indexPath.row], indexPath: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = types[indexPath.row]

        let typeVC = TypeDetailsViewController(type: model)
        //        typeVC.typesModel = model
        //        typeVC.newModel = false
        //typeVC.type = model
        navigationController?.pushViewController(typeVC, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let model = types[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: R.string.global.delete())
        {
            _, _, _ in

            DomainDatabaseService.shared.deleteType(model: model) { [self] success in
                if success {
                    logger.notice("Type \(model.id) deleted successfully")
                    self.configure()

                    tableView.reloadData()
                } else {
                    logger.error("Failed to delete type \(model.id)")
                }
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        let label = UILabel()
        label.text = NSLocalizedString("typeDescription", tableName: "Global", comment: "")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        footer.addSubview(label)
        label.edgesToSuperview(insets: .init(top: 10, left: 16, bottom: 10, right: 16))
        return footer
    }
}
