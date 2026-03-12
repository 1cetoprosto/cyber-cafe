import Foundation
import TinyConstraints
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

        let catalog = OrderProductPickerViewController(
            productsViewModel: viewModel.productsViewModel,
            selectionBehavior: .stayOnSelect
        )
        catalog.title = R.string.global.priceList()

        let receipt = OrderReceiptPadViewController(viewModel: viewModel)
        receipt.onSave = onSave
        receipt.title = R.string.global.order()

        let primaryNav = UINavigationController(rootViewController: catalog)
        let secondaryNav = UINavigationController(rootViewController: receipt)

        let divider = UIView()
        divider.backgroundColor = UIColor.separator

        addChild(primaryNav)
        addChild(secondaryNav)
        view.addSubview(primaryNav.view)
        view.addSubview(divider)
        view.addSubview(secondaryNav.view)
        primaryNav.didMove(toParent: self)
        secondaryNav.didMove(toParent: self)

        primaryNav.view.translatesAutoresizingMaskIntoConstraints = false
        secondaryNav.view.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        let safe = view.safeAreaLayoutGuide
        let preferredFraction: CGFloat = 0.70

        let preferredWidth = primaryNav.view.widthAnchor.constraint(
            equalTo: safe.widthAnchor,
            multiplier: preferredFraction
        )
        preferredWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            primaryNav.view.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            primaryNav.view.topAnchor.constraint(equalTo: safe.topAnchor),
            primaryNav.view.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            divider.leadingAnchor.constraint(equalTo: primaryNav.view.trailingAnchor),
            divider.topAnchor.constraint(equalTo: safe.topAnchor),
            divider.bottomAnchor.constraint(equalTo: safe.bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1),

            secondaryNav.view.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
            secondaryNav.view.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            secondaryNav.view.topAnchor.constraint(equalTo: safe.topAnchor),
            secondaryNav.view.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            preferredWidth,
            primaryNav.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 520),
            primaryNav.view.widthAnchor.constraint(lessThanOrEqualToConstant: 920),
        ])
    }
}
