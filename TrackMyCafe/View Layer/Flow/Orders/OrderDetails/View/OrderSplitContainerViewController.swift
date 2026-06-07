import Foundation
import UIKit

final class OrderSplitContainerViewController: UIViewController {
    private let viewModel: OrderDetailsViewModelType
    var onSave: (() -> Void)?

    init(viewModel: OrderDetailsViewModelType? = nil) {
        self.viewModel =
            viewModel
            ?? OrderDetailsViewModel(
                model: OrderModel(
                    id: "",
                    date: Date(),
                    type: "",
                    sum: 0.0,
                    cash: 0.0,
                    card: 0.0
                ),
                isNewModel: true
            )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background
        navigationItem.largeTitleDisplayMode = .never

        let isCategoryFirstEnabled = SettingsManager.shared
            .loadChooseCategoryFirstProductSelection()

        let pickerRoot: UIViewController
        if isCategoryFirstEnabled {
            let categories = OrderCategoryFirstPickerViewController(
                productsViewModel: viewModel.productsViewModel
            )
            categories.title = NSLocalizedString(
                "orderPicker_allProducts", tableName: "Global", comment: "")
            pickerRoot = categories
        } else {
            let catalog = OrderProductPickerViewController(
                productsViewModel: viewModel.productsViewModel,
                selectionBehavior: .stayOnSelect
            )
            catalog.title = R.string.global.priceList()
            pickerRoot = catalog
        }

        let receipt = OrderReceiptPadViewController(viewModel: viewModel)
        receipt.onSave = onSave
        receipt.title = R.string.global.order()

        let pickerNav = UINavigationController(rootViewController: pickerRoot)
        let receiptNav = UINavigationController(rootViewController: receipt)

        let leftNav = isCategoryFirstEnabled ? receiptNav : pickerNav
        let rightNav = isCategoryFirstEnabled ? pickerNav : receiptNav

        let divider = UIView()
        divider.backgroundColor = UIColor.separator

        addChild(leftNav)
        addChild(rightNav)
        view.addSubview(leftNav.view)
        view.addSubview(divider)
        view.addSubview(rightNav.view)
        leftNav.didMove(toParent: self)
        rightNav.didMove(toParent: self)

        leftNav.view.translatesAutoresizingMaskIntoConstraints = false
        rightNav.view.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        let safe = view.safeAreaLayoutGuide
        let preferredFraction: CGFloat = isCategoryFirstEnabled ? 0.35 : 0.70
        let minLeftWidth: CGFloat = isCategoryFirstEnabled ? 360 : 520
        let maxLeftWidth: CGFloat = isCategoryFirstEnabled ? 560 : 920

        let preferredWidth = leftNav.view.widthAnchor.constraint(
            equalTo: safe.widthAnchor,
            multiplier: preferredFraction
        )
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            leftNav.view.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            leftNav.view.topAnchor.constraint(equalTo: safe.topAnchor),
            leftNav.view.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            divider.leadingAnchor.constraint(equalTo: leftNav.view.trailingAnchor),
            divider.topAnchor.constraint(equalTo: safe.topAnchor),
            divider.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1),

            rightNav.view.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            rightNav.view.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            rightNav.view.topAnchor.constraint(equalTo: safe.topAnchor),
            rightNav.view.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            preferredWidth,
            leftNav.view.widthAnchor.constraint(greaterThanOrEqualToConstant: minLeftWidth),
            leftNav.view.widthAnchor.constraint(lessThanOrEqualToConstant: maxLeftWidth),
        ])
    }
}
