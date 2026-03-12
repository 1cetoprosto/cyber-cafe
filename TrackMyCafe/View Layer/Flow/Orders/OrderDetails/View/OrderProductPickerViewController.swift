import Foundation
import TinyConstraints
import UIKit

final class OrderProductPickerViewController: UIViewController, Loggable {
    enum SelectionBehavior {
        case popOnSelect
        case stayOnSelect
    }

    private enum CategoryConstants {
        static let allId = "__all__"
    }

    private let productsViewModel: ProductListViewModel
    private let selectionBehavior: SelectionBehavior

    var onProductSelected: (() -> Void)?

    private var categories: [ProductCategoryModel] = []
    private var allProducts: [ProductsPriceModel] = []
    private var filteredProducts: [ProductsPriceModel] = []
    private var selectedCategoryId: String?

    private var displayedCategories: [ProductCategoryModel] {
        let allTitle = NSLocalizedString("all", tableName: "Global", comment: "")
        let allCategory = ProductCategoryModel(id: CategoryConstants.allId, name: allTitle, sortOrder: -1)
        return [allCategory] + categories
    }

    private let categoriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = UIConstants.standardPadding
        layout.minimumLineSpacing = UIConstants.standardPadding

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.backgroundColor = UIColor.Main.background
        return collectionView
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        return tableView
    }()

    private lazy var productsCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeProductsLayout())
        collectionView.backgroundColor = UIColor.Main.background
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    init(
        productsViewModel: ProductListViewModel,
        selectionBehavior: SelectionBehavior = .popOnSelect
    ) {
        self.productsViewModel = productsViewModel
        self.selectionBehavior = selectionBehavior
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = R.string.global.products()

        setupCollectionView()
        setupTableView()
        setupProductsCollectionView()
        setupLayout()
        loadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        categoriesCollectionView.flashScrollIndicators()
    }

    private func setupCollectionView() {
        categoriesCollectionView.register(
            CategoryCell.self,
            forCellWithReuseIdentifier: CategoryCell.reuseIdentifier
        )
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProductCell")
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupProductsCollectionView() {
        productsCollectionView.register(
            ProductGridCell.self,
            forCellWithReuseIdentifier: ProductGridCell.reuseIdentifier
        )
        productsCollectionView.delegate = self
        productsCollectionView.dataSource = self
    }

    private func setupLayout() {
        view.addSubview(categoriesCollectionView)
        view.addSubview(tableView)
        view.addSubview(productsCollectionView)

        categoriesCollectionView.topToSuperview(
            offset: UIConstants.standardPadding,
            usingSafeArea: true
        )
        categoriesCollectionView.leftToSuperview(
            offset: UIConstants.standardPadding
        )
        categoriesCollectionView.rightToSuperview(
            offset: -UIConstants.standardPadding
        )
        categoriesCollectionView.height(60)

        tableView.topToBottom(
            of: categoriesCollectionView,
            offset: UIConstants.standardPadding
        )
        tableView.leftToSuperview()
        tableView.rightToSuperview()
        tableView.bottomToSuperview(usingSafeArea: true)

        productsCollectionView.topToBottom(
            of: categoriesCollectionView,
            offset: UIConstants.standardPadding
        )
        productsCollectionView.leftToSuperview()
        productsCollectionView.rightToSuperview()
        productsCollectionView.bottomToSuperview(usingSafeArea: true)

        if UIDevice.isIpad {
            tableView.isHidden = true
        } else {
            productsCollectionView.isHidden = true
        }
    }


    private func loadData() {
        DomainDatabaseService.shared.fetchProductCategories { [weak self] categories in
            DispatchQueue.main.async {
                self?.categories = categories.sorted {
                    if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                    return $0.name < $1.name
                }
                self?.categoriesCollectionView.reloadData()
            }
        }

        DomainDatabaseService.shared.fetchProductsPrice { [weak self] products in
            DispatchQueue.main.async {
                self?.allProducts = products
                self?.applyFilter()
            }
        }
    }

    private func applyFilter() {
        if let id = selectedCategoryId {
            filteredProducts = allProducts.filter { $0.categoryId == id }
        } else {
            filteredProducts = allProducts
        }
        categoriesCollectionView.reloadData()
        if UIDevice.isIpad {
            productsCollectionView.reloadData()
        } else {
            tableView.reloadData()
        }
    }

    private func makeProductsLayout() -> UICollectionViewLayout {
        let spacing = UIConstants.standardPadding
        let minItemWidth: CGFloat = 220

        return UICollectionViewCompositionalLayout { _, environment in
            let contentWidth = environment.container.effectiveContentSize.width
            let columns = max(2, Int((contentWidth + spacing) / (minItemWidth + spacing)))

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(84)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: spacing,
                bottom: spacing,
                trailing: spacing
            )
            section.interGroupSpacing = spacing
            return section
        }
    }
}

extension OrderProductPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === categoriesCollectionView {
            return displayedCategories.count
        }
        if collectionView === productsCollectionView {
            return filteredProducts.count
        }
        return 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if collectionView === categoriesCollectionView {
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CategoryCell.reuseIdentifier,
                    for: indexPath
                ) as? CategoryCell
            else { return UICollectionViewCell() }

            let category = displayedCategories[indexPath.item]
            let isSelected = (category.id == CategoryConstants.allId)
                ? (selectedCategoryId == nil)
                : (category.id == selectedCategoryId)
            cell.configure(title: category.name, isSelected: isSelected)
            return cell
        }

        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProductGridCell.reuseIdentifier,
                for: indexPath
            ) as? ProductGridCell
        else { return UICollectionViewCell() }

        let product = filteredProducts[indexPath.item]
        cell.configure(title: product.name, price: product.price.currency)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard collectionView === categoriesCollectionView else {
            return CGSize(width: 1, height: 1)
        }
        let name = displayedCategories[indexPath.item].name as NSString
        let measured = name.size(withAttributes: [.font: Typography.bodyBold]).width
        let width = max(56, ceil(measured) + 36)
        return CGSize(width: width, height: 44)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if collectionView === categoriesCollectionView {
            let category = displayedCategories[indexPath.item]
            if category.id == CategoryConstants.allId {
                selectedCategoryId = nil
            } else {
                selectedCategoryId = (selectedCategoryId == category.id) ? nil : category.id
            }
            applyFilter()
            return
        }

        collectionView.deselectItem(at: indexPath, animated: true)
        let priceModel = filteredProducts[indexPath.item]
        productsViewModel.addProduct(from: priceModel) { [weak self] in
            guard let self else { return }
            self.onProductSelected?()
            if self.selectionBehavior == .popOnSelect {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

}

extension OrderProductPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ProductCell",
            for: indexPath
        )

        let product = filteredProducts[indexPath.row]
        cell.textLabel?.text = product.name
        cell.detailTextLabel?.text = product.price.currency
        cell.backgroundColor = UIColor.Main.background
        cell.textLabel?.textColor = UIColor.Main.text
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let priceModel = filteredProducts[indexPath.row]
        productsViewModel.addProduct(from: priceModel) { [weak self] in
            guard let self else { return }
            self.onProductSelected?()
            if self.selectionBehavior == .popOnSelect {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
