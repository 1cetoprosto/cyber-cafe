import TinyConstraints
import UIKit

final class OrderProductPickerViewController: UIViewController, Loggable {
    private let productsViewModel: ProductListViewModel

    var onProductSelected: (() -> Void)?

    private enum CategoryIdentifiers {
        static let allCategoryId = "__all__"
    }

    private enum CellIdentifiers {
        static let productGridCell = "ProductGridCell"
    }

    private var categories: [ProductCategoryModel] = []
    private var allProducts: [ProductsPriceModel] = []
    private var filteredProducts: [ProductsPriceModel] = []
    private var selectedCategoryId: String?

    private let categoriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = UIConstants.standardPadding
        layout.minimumLineSpacing = UIConstants.standardPadding

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
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

    init(productsViewModel: ProductListViewModel) {
        self.productsViewModel = productsViewModel
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
            forCellWithReuseIdentifier: CellIdentifiers.productGridCell
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
                let allCategory = ProductCategoryModel(
                    id: CategoryIdentifiers.allCategoryId,
                    name: R.string.global.all(),
                    sortOrder: -1
                )
                self?.categories = [allCategory] + categories
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

extension OrderProductPickerViewController: UICollectionViewDelegate,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === categoriesCollectionView {
            return categories.count
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

            let category = categories[indexPath.item]
            cell.configure(with: category.name)
            return cell
        }

        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CellIdentifiers.productGridCell,
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

        let name = categories[indexPath.item].name as NSString
        let width = name.size(withAttributes: [.font: Typography.body]).width
        return CGSize(width: width + 24, height: 40)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if collectionView === categoriesCollectionView {
            let category = categories[indexPath.item]
            selectedCategoryId =
                category.id == CategoryIdentifiers.allCategoryId
                ? nil
                : category.id
            applyFilter()
            return
        }

        collectionView.deselectItem(at: indexPath, animated: true)

        let priceModel = filteredProducts[indexPath.item]
        productsViewModel.addProduct(from: priceModel) { [weak self] in
            self?.onProductSelected?()
            self?.navigationController?.popViewController(animated: true)
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
            self?.onProductSelected?()
            self?.navigationController?.popViewController(animated: true)
        }
    }
}

private final class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.body)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.Main.secondaryBackground
        contentView.layer.cornerRadius = 12

        contentView.addSubview(titleLabel)
        titleLabel.edgesToSuperview(insets: .horizontal(8))
        titleLabel.centerYToSuperview()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}

private final class ProductGridCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Main.text
        label.numberOfLines = 2
        label.applyDynamic(Typography.bodyMedium)
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Main.text
        label.textAlignment = .right
        label.applyDynamic(Typography.body)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.white
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)

        titleLabel.topToSuperview(offset: 10)
        titleLabel.leftToSuperview(offset: 12)
        titleLabel.rightToSuperview(offset: -12)

        priceLabel.topToBottom(of: titleLabel, offset: 8, relation: .equalOrLess)
        priceLabel.leftToSuperview(offset: 12)
        priceLabel.rightToSuperview(offset: -12)
        priceLabel.bottomToSuperview(offset: -10)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(title: String, price: String) {
        titleLabel.text = title
        priceLabel.text = price
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.alpha = isHighlighted ? 0.7 : 1.0
        }
    }
}
