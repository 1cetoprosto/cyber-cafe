import TinyConstraints
import UIKit

final class OrderCategoryFirstPickerViewController: UIViewController {
    private let productsViewModel: ProductListViewModel

    private var allCategories: [ProductCategoryModel] = []
    private var categories: [ProductCategoryModel] = []
    private var allProducts: [ProductsPriceModel] = []

    private var searchText: String = "" {
        didSet { applyFilter() }
    }

    private var collectionBottomConstraint: Constraint?

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
        title = R.string.global.orderPicker_allProducts()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .never
        // Keep search under the nav title. Automatic/toolbar placement on recent iOS
        // puts the bar under the return button and makes push transitions hitch.
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        if #available(iOS 26.0, *) {
            navigationItem.searchBarPlacementAllowsToolbarIntegration = false
        }

        applyNavigationBarAppearance()
        configureNavigationItems()
        setupCollectionView()
        setupLayout()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReturnToOrderButtonVisibility()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureNavigationItems()
        updateReturnToOrderButtonVisibility()
    }

    private func applyNavigationBarAppearance() {
        guard let navigationController else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.NavBar.background
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.NavBar.text
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.NavBar.text
        ]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = UIColor.NavBar.text
        navigationController.navigationBar.isTranslucent = false
        navigationController.view.backgroundColor = UIColor.NavBar.background
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = nil

        if traitCollection.horizontalSizeClass == .regular {
            navigationItem.backButtonTitle = R.string.global.orderPicker_allProducts()
        } else {
            navigationItem.backButtonTitle = R.string.global.back()
        }

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
            OrderPickerCategoryGridCell.self,
            forCellWithReuseIdentifier: OrderPickerCategoryGridCell.reuseIdentifier
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
        returnToOrderButton.bottomToSuperview(
            offset: -UIConstants.standardPadding, usingSafeArea: true)
        returnToOrderButton.height(UIConstants.buttonHeight)
        returnToOrderButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    private func loadData() {
        Task { [weak self] in
            async let categoriesResult = DomainDatabaseService.shared.fetchProductCategories()
            async let productsResult = DomainDatabaseService.shared.fetchProductsPrice()
            let (categories, products) = await (categoriesResult, productsResult)

            await MainActor.run {
                guard let self else { return }
                self.allProducts = products
                self.allCategories = categories.sorted {
                    if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                self.applyFilter()
            }
        }
    }

    private func applyFilter() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            categories = allCategories
        } else {
            categories = allCategories.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }

        collectionView.reloadData()

        if categories.isEmpty {
            emptyStateLabel.isHidden = false
            emptyStateLabel.text =
                trimmed.isEmpty
                ? R.string.global.orderPicker_emptyCategories()
                : R.string.global.orderPicker_noResults()
        } else {
            emptyStateLabel.isHidden = true
        }
    }

    private func updateReturnToOrderButtonVisibility() {
        let shouldShow = traitCollection.horizontalSizeClass == .compact
        returnToOrderButton.isHidden = !shouldShow
        collectionBottomConstraint?.constant =
            shouldShow
            ? -(UIConstants.buttonHeight + UIConstants.standardPadding * 2)
            : 0
        view.setNeedsLayout()
    }

    private func makeLayout() -> UICollectionViewLayout {
        let spacing = UIConstants.standardPadding
        let minItemWidth: CGFloat = 140
        // Match OrderPickerCategoryGridCell: 12 inset + image (2/3 width) + 10 + ~40 title + 12
        let verticalChrome: CGFloat = 12 + 10 + 40 + 12
        let imageAspectRatio: CGFloat = 2.0 / 3.0

        return UICollectionViewCompositionalLayout { _, environment in
            let contentWidth = environment.container.effectiveContentSize.width
            let availableWidth = max(0, contentWidth - spacing * 2)
            let columns = max(1, Int((availableWidth + spacing) / (minItemWidth + spacing)))
            let interItemTotal = spacing * CGFloat(max(0, columns - 1))
            let itemWidth = floor((availableWidth - interItemTotal) / CGFloat(columns))
            let imageHeight = (itemWidth - 24) * imageAspectRatio
            let itemHeight = ceil(verticalChrome + imageHeight)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemHeight)
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
}

extension OrderCategoryFirstPickerViewController: UICollectionViewDataSource,
    UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int {
        categories.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderPickerCategoryGridCell.reuseIdentifier,
                for: indexPath
            ) as? OrderPickerCategoryGridCell
        else { return UICollectionViewCell() }

        let category = categories[indexPath.item]
        cell.configure(title: category.name, imagePath: category.imagePath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Push immediately — never await network on the tap path (that caused the visible hang).
        let category = categories[indexPath.item]
        let productsVC = OrderCategoryFirstProductsViewController(
            productsViewModel: productsViewModel,
            category: category,
            allProducts: allProducts
        )
        navigationController?.pushViewController(productsVC, animated: true)
    }
}

extension OrderCategoryFirstPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
    }
}
