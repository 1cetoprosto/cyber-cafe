import TinyConstraints
import UIKit

final class OrderProductPickerViewController: UIViewController, Loggable {
    private let productsViewModel: ProductListViewModel

    var onProductSelected: (() -> Void)?

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

    private func setupLayout() {
        view.addSubview(categoriesCollectionView)
        view.addSubview(tableView)

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
    }

    private func loadData() {
        DomainDatabaseService.shared.fetchProductCategories { [weak self] categories in
            DispatchQueue.main.async {
                self?.categories = categories
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
        tableView.reloadData()
    }
}

extension OrderProductPickerViewController: UICollectionViewDelegate,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return categories.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
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

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let name = categories[indexPath.item].name as NSString
        let width = name.size(withAttributes: [.font: Typography.body]).width
        return CGSize(width: width + 24, height: 40)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let category = categories[indexPath.item]
        selectedCategoryId = category.id
        applyFilter()
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
