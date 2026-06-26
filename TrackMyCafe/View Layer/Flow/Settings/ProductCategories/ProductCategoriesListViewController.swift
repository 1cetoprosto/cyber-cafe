import TinyConstraints
import UIKit

final class ProductCategoriesListViewController: UIViewController, Loggable {
    private var categories: [ProductCategoryModel] = []

    private let tableView: UITableView = {
        UITableView.standardList()
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
        let sortOrder = (categories.map { $0.sortOrder }.max() ?? 0) + 1
        let newCategory = ProductCategoryModel(
            id: UUID().uuidString,
            name: "",
            sortOrder: sortOrder
        )
        showDetails(for: newCategory, isNew: true)
    }

    private func showDetails(for category: ProductCategoryModel, isNew: Bool) {
        let title = isNew ? R.string.global.add() : R.string.global.edit()
        let vm = ProductCategoryDetailsViewModel(
            title: title,
            model: category,
            dataService: DomainProductCategoryDataService()
        )
        let vc = ProductCategoryDetailsViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
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
        let placeholder = AppImagePlaceholder.category()
        content.image = placeholder
        cell.contentConfiguration = content

        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        cell.imageView?.setImage(pathOrURL: category.imagePath, placeholder: placeholder)

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
                    Task {
                        _ = try? await FirebaseImageStorageService.shared.delete(
                            atPath: ImageStoragePaths.productCategoryImagePath(categoryId: model.id)
                        )
                    }
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
        showDetails(for: category, isNew: false)
    }
}
