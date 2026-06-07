import TinyConstraints
import UIKit

final class OrderCategoryFirstProductsViewController: UIViewController {
    private let productsViewModel: ProductListViewModel
    private let category: ProductCategoryModel
    private let allProducts: [ProductsPriceModel]

    private var products: [ProductsPriceModel] = []
    private var filteredProducts: [ProductsPriceModel] = []

    private var searchText: String = "" {
        didSet { applyFilter() }
    }

    private var isCompactWidth: Bool {
        traitCollection.horizontalSizeClass == .compact
    }

    private var collectionBottomConstraint: Constraint?

    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.backgroundColor = UIColor.Main.background
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.Main.text.withAlphaComponent(0.6)
        label.applyDynamic(Typography.body)
        label.isHidden = true
        return label
    }()

    private let returnToOrderButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(
            NSLocalizedString("orderPicker_returnToOrder", tableName: "Global", comment: ""),
            for: .normal
        )
        button.isHidden = true
        return button
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.autocapitalizationType = .none
        controller.searchBar.placeholder = R.string.global.search()
        return controller
    }()

    init(
        productsViewModel: ProductListViewModel,
        category: ProductCategoryModel,
        allProducts: [ProductsPriceModel]
    ) {
        self.productsViewModel = productsViewModel
        self.category = category
        self.allProducts = allProducts
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background
        title = category.name
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        configureNavigationItems()
        setupCollectionView()
        setupLayout()
        setupObservers()
        setupData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReturnToOrderButtonVisibility()
        collectionView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureNavigationItems()
        updateReturnToOrderButtonVisibility()
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = nil

        if navigationController?.presentingViewController != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )
        }

        if traitCollection.horizontalSizeClass == .regular {
            let camera = UIBarButtonItem(
                image: UIImage(systemName: "camera"),
                style: .plain,
                target: self,
                action: #selector(cameraTapped)
            )
            let barcode = UIBarButtonItem(
                image: UIImage(systemName: "barcode.viewfinder"),
                style: .plain,
                target: self,
                action: #selector(barcodeTapped)
            )
            if navigationController?.presentingViewController != nil {
                navigationItem.leftBarButtonItems = [camera, barcode]
            } else {
                navigationItem.rightBarButtonItems = [barcode, camera]
            }
        }
    }

    private func setupCollectionView() {
        collectionView.collectionViewLayout = makeLayout()
        collectionView.register(
            OrderPickerProductTileCell.self,
            forCellWithReuseIdentifier: OrderPickerProductTileCell.reuseIdentifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        view.addSubview(returnToOrderButton)

        collectionView.topToSuperview(usingSafeArea: true)
        collectionView.leftToSuperview(usingSafeArea: true)
        collectionView.rightToSuperview(usingSafeArea: true)
        collectionBottomConstraint = collectionView.bottomToSuperview(usingSafeArea: true)

        emptyStateLabel.centerInSuperview()
        emptyStateLabel.leftToSuperview(offset: 24)
        emptyStateLabel.rightToSuperview(offset: -24)

        returnToOrderButton.leftToSuperview(offset: UIConstants.standardPadding)
        returnToOrderButton.rightToSuperview(offset: -UIConstants.standardPadding)
        returnToOrderButton.bottomToSuperview(offset: -UIConstants.standardPadding, usingSafeArea: true)
        returnToOrderButton.height(UIConstants.buttonHeight)
        returnToOrderButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(productListDidChange(_:)),
            name: .productListDidChange,
            object: productsViewModel
        )
    }

    private func setupData() {
        products = allProducts.filter { $0.categoryId == category.id }
        products.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        applyFilter()
    }

    private func applyFilter() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }

        collectionView.reloadData()

        if filteredProducts.isEmpty {
            emptyStateLabel.isHidden = false
            emptyStateLabel.text =
                trimmed.isEmpty
                ? NSLocalizedString("orderPicker_emptyProducts", tableName: "Global", comment: "")
                : NSLocalizedString("orderPicker_noResults", tableName: "Global", comment: "")
        } else {
            emptyStateLabel.isHidden = true
        }
    }

    private func updateReturnToOrderButtonVisibility() {
        let shouldShow = isCompactWidth
        returnToOrderButton.isHidden = !shouldShow
        collectionBottomConstraint?.constant =
            shouldShow
            ? -(UIConstants.buttonHeight + UIConstants.standardPadding * 2)
            : 0
        view.setNeedsLayout()
    }

    private func makeLayout() -> UICollectionViewLayout {
        let spacing = UIConstants.standardPadding
        let minItemWidth: CGFloat = 180

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
                heightDimension: .absolute(168)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: spacing,
                leading: spacing,
                bottom: spacing,
                trailing: spacing
            )
            section.interGroupSpacing = spacing
            return section
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func cameraTapped() {
    }

    @objc private func barcodeTapped() {
    }

    @objc private func productListDidChange(_ note: Notification) {
        guard view.window != nil else { return }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

extension OrderCategoryFirstProductsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredProducts.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderPickerProductTileCell.reuseIdentifier,
                for: indexPath
            ) as? OrderPickerProductTileCell
        else { return UICollectionViewCell() }

        let product = filteredProducts[indexPath.item]
        let qty = productsViewModel.quantity(forProductId: product.id) ?? 0

        cell.configure(
            title: product.name,
            price: product.price.currency,
            quantity: qty
        )

        cell.onMinusTapped = { [weak self] in
            guard let self else { return }
            self.decrementQuantity(for: product.id)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let product = filteredProducts[indexPath.item]

        productsViewModel.addProduct(from: product) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }

    private func decrementQuantity(for productId: String) {
        guard
            let idx = productsViewModel.index(forProductId: productId),
            let current = productsViewModel.quantity(forProductId: productId),
            current > 0
        else { return }

        let newValue = max(0, current - 1)
        productsViewModel.setQuantity(tag: idx, quantity: newValue)
    }
}

extension OrderCategoryFirstProductsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
    }
}
