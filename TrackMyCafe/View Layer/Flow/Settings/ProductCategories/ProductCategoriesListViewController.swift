import TinyConstraints
import UIKit

final class ProductCategoriesListViewController: UIViewController, Loggable {
    private var categories: [ProductCategoryModel] = []

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        return tableView
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = R.string.global.products()

        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "CategoryCell"
        )
        tableView.dataSource = self
        tableView.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addCategory)
        )

        setupConstraints()
    }

    private func setupConstraints() {
        view.addSubview(tableView)
        tableView.edgesToSuperview()
    }

    private func loadData() {
        DomainDatabaseService.shared.fetchProductCategories { [weak self] categories in
            self?.categories = categories
            self?.tableView.reloadData()
        }
    }

    @objc private func addCategory() {
        presentCategoryAlert(category: nil)
    }

    private func presentCategoryAlert(category: ProductCategoryModel?) {
        let isEditing = category != nil
        let alert = UIAlertController(
            title: isEditing
                ? R.string.global.edit()
                : R.string.global.add(),
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = R.string.global.enterProductName()
            textField.text = category?.name
        }

        alert.addAction(
            UIAlertAction(title: R.string.global.cancel(), style: .cancel)
        )

        alert.addAction(
            UIAlertAction(title: R.string.global.save(), style: .default) { [weak self] _ in
                guard let self = self else { return }
                guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }

                if var existing = category {
                    existing.name = name
                    DomainDatabaseService.shared.saveProductCategory(category: existing) {
                        success in
                        if success {
                            self.logger.notice(
                                "Product category \(existing.id) updated successfully")
                            self.loadData()
                        } else {
                            self.logger.error("Failed to update product category \(existing.id)")
                        }
                    }
                } else {
                    let sortOrder = (self.categories.map { $0.sortOrder }.max() ?? 0) + 1
                    let newCategory = ProductCategoryModel(
                        id: UUID().uuidString,
                        name: name,
                        sortOrder: sortOrder
                    )
                    DomainDatabaseService.shared.saveProductCategory(category: newCategory) {
                        success in
                        if success {
                            self.logger.notice(
                                "Product category \(newCategory.id) created successfully")
                            self.loadData()
                        } else {
                            self.logger.error("Failed to create product category \(newCategory.id)")
                        }
                    }
                }
            }
        )

        present(alert, animated: true)
    }
}

extension ProductCategoriesListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        )
        let category = categories[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = category.name
        cell.contentConfiguration = content
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let model = categories[indexPath.row]

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: R.string.global.delete()
        ) { [weak self] _, _, _ in
            guard let self = self else { return }
            DomainDatabaseService.shared.deleteProductCategory(model: model) { success in
                if success {
                    self.logger.notice("Product category \(model.id) deleted successfully")
                    self.loadData()
                } else {
                    self.logger.error("Failed to delete product category \(model.id)")
                }
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let category = categories[indexPath.row]
        presentCategoryAlert(category: category)
    }
}
