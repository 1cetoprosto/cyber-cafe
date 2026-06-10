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
        title = NSLocalizedString("orderPicker_allProducts", tableName: "Global", comment: "")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        configureNavigationItems()
        setupCollectionView()
        setupLayout()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReturnToOrderButtonVisibility()
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

        if traitCollection.horizontalSizeClass == .regular {
            navigationItem.backButtonTitle = NSLocalizedString(
                "orderPicker_allProducts",
                tableName: "Global",
                comment: ""
            )
        } else {
            navigationItem.backButtonTitle = NSLocalizedString(
                "back", tableName: "Global", comment: "")
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
        DomainDatabaseService.shared.fetchProductCategories { [weak self] categories in
            DispatchQueue.main.async {
                self?.allCategories = categories.sorted {
                    if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                self?.applyFilter()
            }
        }

        DomainDatabaseService.shared.fetchProductsPrice { [weak self] products in
            DispatchQueue.main.async {
                self?.allProducts = products
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
                ? NSLocalizedString("orderPicker_emptyCategories", tableName: "Global", comment: "")
                : NSLocalizedString("orderPicker_noResults", tableName: "Global", comment: "")
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

        return UICollectionViewCompositionalLayout { _, environment in
            let contentWidth = environment.container.effectiveContentSize.width
            let columns = max(2, Int((contentWidth + spacing) / (minItemWidth + spacing)))

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(160)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(160)
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
}

extension OrderCategoryFirstPickerViewController: UICollectionViewDataSource,
    UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
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
