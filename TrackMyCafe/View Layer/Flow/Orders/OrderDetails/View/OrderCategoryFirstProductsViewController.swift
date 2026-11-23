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

    private var usesCompactList: Bool {
        traitCollection.horizontalSizeClass == .compact
    }

    private var tableBottomConstraint: Constraint?
    private var collectionBottomConstraint: Constraint?

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        tableView.register(
            OrderTableViewCell.self,
            forCellReuseIdentifier: CellIdentifiers.orderCell
        )
        return tableView
    }()

    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.backgroundColor = UIColor.Main.background
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    private let emptyStateLabel: UILabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.Main.text.withAlphaComponent(0.6)
        label.apply(.body)
        label.isHidden = true
        return label
    }()

    private let returnToOrderButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(
            R.string.global.orderPicker_returnToOrder(),
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
        setupTableView()
        setupLayout()
        setupObservers()
        setupData()
        updateChromeForSizeClass()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateChromeForSizeClass()
        reloadVisibleList()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureNavigationItems()
        updateChromeForSizeClass()
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

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        view.addSubview(returnToOrderButton)

        tableView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        collectionView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        tableBottomConstraint = tableView.bottomToSuperview(usingSafeArea: true)
        collectionBottomConstraint = collectionView.bottomToSuperview(usingSafeArea: true)

        emptyStateLabel.centerInSuperview()
        emptyStateLabel.leftToSuperview(offset: 24)
        emptyStateLabel.rightToSuperview(offset: -24)

        returnToOrderButton.leftToSuperview(offset: UIConstants.standardPadding)
        returnToOrderButton.rightToSuperview(offset: -UIConstants.standardPadding)
        returnToOrderButton.bottomToSuperview(
            offset: -UIConstants.standardPadding, usingSafeArea: true)
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

        reloadVisibleList()

        if filteredProducts.isEmpty {
            emptyStateLabel.isHidden = false
            emptyStateLabel.text =
                trimmed.isEmpty
                ? R.string.global.orderPicker_emptyProducts()
                : R.string.global.orderPicker_noResults()
        } else {
            emptyStateLabel.isHidden = true
        }
    }

    private func updateChromeForSizeClass() {
        let compact = usesCompactList
        tableView.isHidden = !compact
        collectionView.isHidden = compact

        let shouldShowReturn = compact
        returnToOrderButton.isHidden = !shouldShowReturn
        let bottomInset: CGFloat =
            shouldShowReturn
            ? -(UIConstants.buttonHeight + UIConstants.standardPadding * 2)
            : 0
        tableBottomConstraint?.constant = bottomInset
        collectionBottomConstraint?.constant = 0
        view.setNeedsLayout()
        reloadVisibleList()
    }

    private func reloadVisibleList() {
        if usesCompactList {
            tableView.reloadData()
        } else {
            collectionView.reloadData()
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        let spacing = UIConstants.standardPadding
        let minItemWidth: CGFloat = 180

        return UICollectionViewCompositionalLayout { _, environment in
            let contentWidth = environment.container.effectiveContentSize.width
            let columns = max(2, Int((contentWidth + spacing) / (minItemWidth + spacing)))

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(220)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(220)
            )
            let group: NSCollectionLayoutGroup
            if #available(iOS 16.0, *) {
                group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    repeatingSubitem: item,
                    count: columns
                )
            } else {
                group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: columns
                )
            }
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
        DispatchQueue.main.async { [weak self] in
            self?.reloadVisibleList()
        }
    }

    @objc private func stepperChanged(_ sender: UIStepper) {
        let quantity = Int(sender.value)
        guard let productId = sender.accessibilityIdentifier, !productId.isEmpty else { return }

        if let idx = productsViewModel.index(forProductId: productId) {
            productsViewModel.setQuantity(tag: idx, quantity: quantity)
            reloadVisibleList()
            return
        }

        guard quantity > 0,
            let product = filteredProducts.first(where: { $0.id == productId })
        else {
            reloadVisibleList()
            return
        }

        Task { [weak self] in
            guard let self else { return }
            await productsViewModel.addProduct(from: product)
            if let idx = productsViewModel.index(forProductId: productId) {
                productsViewModel.setQuantity(tag: idx, quantity: quantity)
            }
            await MainActor.run {
                self.reloadVisibleList()
            }
        }
    }

    private func incrementProduct(_ product: ProductsPriceModel) {
        Task { [weak self] in
            guard let self else { return }
            await productsViewModel.addProduct(from: product)
            await MainActor.run {
                self.reloadVisibleList()
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
        reloadVisibleList()
    }
}

// MARK: - UITableView (iPhone compact list)

extension OrderCategoryFirstProductsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredProducts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CellIdentifiers.orderCell, for: indexPath
            ) as? OrderTableViewCell
        else { return UITableViewCell() }

        let product = filteredProducts[indexPath.row]
        let qty = productsViewModel.quantity(forProductId: product.id) ?? 0

        cell.productLabel.text = "\(product.name) · \(product.price.currency)"
        cell.quantityLabel.text = "\(qty)"
        cell.productStepper.minimumValue = 0
        cell.productStepper.maximumValue = 999
        cell.productStepper.value = Double(qty)
        cell.productStepper.accessibilityIdentifier = product.id
        cell.productStepper.removeTarget(nil, action: nil, for: .valueChanged)
        cell.productStepper.addTarget(
            self, action: #selector(stepperChanged(_:)), for: .valueChanged)

        cell.applyListStyle(row: indexPath.row, totalRows: filteredProducts.count)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        incrementProduct(filteredProducts[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }
}

// MARK: - UICollectionView (iPad tile grid)

extension OrderCategoryFirstProductsViewController: UICollectionViewDataSource,
    UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
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
            quantity: qty,
            imagePath: product.imagePath
        )

        cell.onMinusTapped = { [weak self] in
            self?.decrementQuantity(for: product.id)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        incrementProduct(filteredProducts[indexPath.item])
    }
}

extension OrderCategoryFirstProductsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
    }
}
