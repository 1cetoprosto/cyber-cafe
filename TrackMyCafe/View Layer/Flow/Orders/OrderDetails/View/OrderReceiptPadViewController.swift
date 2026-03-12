import Foundation
import TinyConstraints
import UIKit

private struct OrderReceiptItem: Hashable {
    let productId: String
}

private final class OrderCompactFieldView: UIControl {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.footnoteLight)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.footnote)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.TableView.cellBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.clear.cgColor

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.edgesToSuperview(insets: .uniform(8))

        titleLabel.isUserInteractionEnabled = false
        valueLabel.isUserInteractionEnabled = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        isAccessibilityElement = true
        accessibilityTraits = [.button]
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(title: String, value: String) {
        titleLabel.text = "\(title):"
        valueLabel.text = value
        accessibilityLabel = "\(title): \(value)"
    }

    func setHighlightedState(_ isHighlighted: Bool) {
        layer.borderColor = (isHighlighted ? UIColor.Main.text : UIColor.clear).cgColor
    }
}

final class OrderReceiptPadViewController: UIViewController, UITextFieldDelegate, Loggable {
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.setLocalizedDateFormatFromTemplate("ddMMyy")
        return formatter
    }()
    private let viewModel: OrderDetailsViewModelType
    private var selectedDate: Date
    private var selectedType: String
    private var availableTypes: [TypeModel] = []

    var onSave: (() -> Void)?

    private let headerContainer = UIView()
    private let dateFieldView = OrderCompactFieldView()
    private let typeFieldView = OrderCompactFieldView()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        return tableView
    }()

    private let footerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.Main.background
        return view
    }()

    private lazy var noteInputContainer: InputContainerView = {
        InputContainerView(
            labelText: "",
            inputType: .text(keyboardType: .default),
            isEditable: true,
            placeholder: ""
        )
    }()

    private let orderLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "0"
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.title3)
        return label
    }()

    private let totalTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.title3)
        return label
    }()

    private let changeTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.body)
        return label
    }()

    private let changeValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = UIColor.Main.text
        label.applyDynamic(Typography.body)
        return label
    }()

    private lazy var changeStackView: UIStackView = {
        UIStackView(
            arrangedSubviews: [changeTitleLabel, changeValueLabel],
            axis: .horizontal,
            spacing: UIConstants.smallSpacing,
            distribution: .fill
        )
    }()

    private lazy var cashInputContainer: InputContainerView = {
        InputContainerView(
            labelText: "",
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0"
        )
    }()

    private lazy var cardInputContainer: InputContainerView = {
        InputContainerView(
            labelText: "",
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: "0"
        )
    }()

    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.save(), for: .normal)
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        return button
    }()

    private var dataSource: UITableViewDiffableDataSource<Int, OrderReceiptItem>?

    init(viewModel: OrderDetailsViewModelType) {
        self.viewModel = viewModel
        self.selectedDate = viewModel.date
        self.selectedType = viewModel.type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = R.string.global.order()
        view.backgroundColor = UIColor.Main.background

        setupHeader()
        setupTable()
        setupFooter()
        setupInputs()
        setupBindings()
        loadInitialData()
    }

    private func setupHeader() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(dateFieldView)
        headerContainer.addSubview(typeFieldView)

        let spacing = UIConstants.standardPadding
        headerContainer.topToSuperview(usingSafeArea: true)
        headerContainer.leftToSuperview(offset: spacing)
        headerContainer.rightToSuperview(offset: -spacing)
        headerContainer.height(40 + spacing * 2)

        dateFieldView.topToSuperview(offset: spacing)
        typeFieldView.topToSuperview(offset: spacing)
        dateFieldView.leftToSuperview()
        typeFieldView.rightToSuperview()
        dateFieldView.rightToLeft(of: typeFieldView, offset: -spacing)
        dateFieldView.width(to: typeFieldView)
        dateFieldView.height(40)
        typeFieldView.height(40)

        dateFieldView.addTarget(self, action: #selector(dateTapped), for: .touchUpInside)
        typeFieldView.addTarget(self, action: #selector(typeTapped), for: .touchUpInside)

        updateHeader()
    }

    private func setupTable() {
        view.addSubview(tableView)
        tableView.register(OrderTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.orderCell)
        tableView.delegate = self

        configureDataSource()
    }

    private func setupFooter() {
        view.addSubview(footerContainer)

        footerContainer.leftToSuperview()
        footerContainer.rightToSuperview()
        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true

        tableView.topToBottom(of: headerContainer, offset: UIConstants.standardPadding)
        tableView.leftToSuperview()
        tableView.rightToSuperview()
        tableView.bottomToTop(of: footerContainer)

        let content = UIView()
        footerContainer.addSubview(content)
        content.edgesToSuperview(insets: .uniform(UIConstants.standardPadding))

        let cashCardStackView = UIStackView(
            arrangedSubviews: [cashInputContainer, cardInputContainer],
            axis: .horizontal,
            spacing: UIConstants.standardPadding,
            distribution: .fillEqually
        )

        noteInputContainer.setDelegate(self)
        noteInputContainer.setReturnKeyType(.done)
        noteInputContainer.configure(labelText: R.string.global.note())
        noteInputContainer.textFieldReference?.textAlignment = .left
        noteInputContainer.textFieldReference?.font = Typography.body
        noteInputContainer.textFieldReference?.adjustsFontForContentSizeCategory = true
        noteInputContainer.text = viewModel.note

        let totalStackView = UIStackView(
            arrangedSubviews: [totalTitleLabel, orderLabel],
            axis: .horizontal,
            spacing: UIConstants.smallSpacing,
            distribution: .fill
        )

        let stack = UIStackView(
            arrangedSubviews: [totalStackView, cashCardStackView, noteInputContainer, changeStackView, saveButton]
        )
        stack.axis = .vertical
        stack.spacing = UIConstants.standardPadding
        stack.distribution = .fill
        stack.alignment = .fill
        content.addSubview(stack)
        stack.edgesToSuperview()

        saveButton.height(UIConstants.buttonHeight)

        totalTitleLabel.text = viewModel.orderLabel
        changeTitleLabel.text = NSLocalizedString("changeDue", tableName: "Global", comment: "")
        updateTotals()
        updateChangeLabel()
    }

    private func setupInputs() {
        cashInputContainer.setDelegate(self)
        cardInputContainer.setDelegate(self)
        cashInputContainer.enableNumericInput(maxFractionDigits: 2)
        cardInputContainer.enableNumericInput(maxFractionDigits: 2)

        let currencySymbol =
            RequestManager.shared.settings?.currencySymbol
            ?? ((Locale.current.languageCode == "uk")
                ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)

        cashInputContainer.enableCurrencySuffix(symbol: currencySymbol)
        cardInputContainer.enableCurrencySuffix(symbol: currencySymbol)

        cashInputContainer.setReturnKeyType(.done)
        cardInputContainer.setReturnKeyType(.done)

        cashInputContainer.textFieldReference?.textAlignment = .right
        cardInputContainer.textFieldReference?.textAlignment = .right

        cashInputContainer.configure(labelText: viewModel.cashLabel)
        cardInputContainer.configure(labelText: viewModel.cardLabel)

        cashInputContainer.onTextChange = { [weak self] _ in
            self?.updateChangeLabel()
        }
        cardInputContainer.onTextChange = { [weak self] _ in
            self?.updateChangeLabel()
        }

        if viewModel.cash != 0 { cashInputContainer.text = viewModel.cash.decimalFormat }
        if viewModel.card != 0 { cardInputContainer.text = viewModel.card.decimalFormat }
    }

    private func setupBindings() {
        viewModel.productsViewModel.onChange = { [weak self] change in
            DispatchQueue.main.async {
                self?.handleProductsChange(change)
            }
        }
    }

    private func loadInitialData() {
        viewModel.loadProducts { [weak self] in
            DispatchQueue.main.async {
                self?.applySnapshot(animatingDifferences: false)
                self?.updateTotals()
                self?.updateChangeLabel()
            }
        }

        if selectedType.isEmpty, viewModel.isNewModel {
            DomainDatabaseService.shared.fetchTypes { [weak self] types in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.availableTypes = types
                    if let def = types.first(where: { $0.isDefault }) {
                        self.selectedType = def.name
                        self.updateHeader()
                    }
                }
            }
        } else {
            DomainDatabaseService.shared.fetchTypes { [weak self] types in
                DispatchQueue.main.async {
                    self?.availableTypes = types
                }
            }
        }
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, OrderReceiptItem>(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, item in
                guard
                    let self,
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: CellIdentifiers.orderCell,
                        for: indexPath
                    ) as? OrderTableViewCell
                else {
                    return UITableViewCell()
                }

                guard let index = self.viewModel.productsViewModel.index(forProductId: item.productId) else {
                    return cell
                }
                let vm = self.viewModel.productsViewModel.cellViewModel(
                    for: IndexPath(row: index, section: 0)
                )
                cell.viewModel = vm
                let totalRows = self.viewModel.productsViewModel.activeProductIds().count
                cell.applyListStyle(row: indexPath.row, totalRows: totalRows)
                cell.productStepper.addTarget(
                    self,
                    action: #selector(self.stepperValueChanged(_:)),
                    for: .valueChanged
                )
                return cell
            }
        )
    }

    private func applySnapshot(animatingDifferences: Bool) {
        guard let dataSource else { return }
        let items = viewModel.productsViewModel.activeProductIds().map { OrderReceiptItem(productId: $0) }
        var snapshot = NSDiffableDataSourceSnapshot<Int, OrderReceiptItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func handleProductsChange(_ change: ProductListChange) {
        updateTotals()
        updateChangeLabel()

        switch change {
        case .fullReload:
            applySnapshot(animatingDifferences: true)
        case .productUpdated(let productId):
            guard let dataSource else { return }
            let items = dataSource.snapshot().itemIdentifiers
            if let quantity = viewModel.productsViewModel.quantity(forProductId: productId), quantity == 0 {
                applySnapshot(animatingDifferences: true)
                return
            }
            guard items.contains(where: { $0.productId == productId }) else {
                applySnapshot(animatingDifferences: true)
                return
            }

            var snapshot = dataSource.snapshot()
            snapshot.reconfigureItems([OrderReceiptItem(productId: productId)])
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

    private func updateTotals() {
        orderLabel.text = viewModel.productsViewModel.totalSum()
    }

    private func updateChangeLabel() {
        let total = viewModel.productsViewModel.getTotalAmount()
        let cash = cashInputContainer.text?.doubleOrZero ?? 0
        let card = cardInputContainer.text?.doubleOrZero ?? 0

        let dueAfterCard = max(0, total - card)
        let change = max(0, cash - dueAfterCard)

        let hasCashInput =
            !(cashInputContainer.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty ?? true)
        changeStackView.isHidden = !hasCashInput
        changeValueLabel.text = change.currency
    }

    private func updateHeader() {
        dateFieldView.configure(
            title: R.string.global.costDate(),
            value: Self.shortDateFormatter.string(from: selectedDate)
        )
        typeFieldView.configure(
            title: R.string.global.type(),
            value: selectedType.isEmpty ? R.string.global.chooseType() : selectedType
        )
    }

    @objc private func dateTapped() {
        dateFieldView.setHighlightedState(true)
        let pickerVC = UIViewController()
        pickerVC.view.backgroundColor = UIColor.Main.background
        pickerVC.preferredContentSize = CGSize(width: 320, height: 360)

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.date = selectedDate

        pickerVC.view.addSubview(picker)
        picker.edgesToSuperview(insets: .uniform(UIConstants.standardPadding), usingSafeArea: true)

        pickerVC.modalPresentationStyle = .popover
        if let pop = pickerVC.popoverPresentationController {
            pop.sourceView = dateFieldView
            pop.sourceRect = dateFieldView.bounds
            pop.permittedArrowDirections = [.up, .down]
            pop.delegate = self
        }

        picker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        present(pickerVC, animated: true)
    }

    @objc private func datePickerChanged(_ picker: UIDatePicker) {
        selectedDate = picker.date
        updateHeader()
    }

    @objc private func typeTapped() {
        typeFieldView.setHighlightedState(true)
        let items = availableTypes
        let selection = SelectionViewController<TypeModel>(
            items: items,
            configureCell: { cell, item in
                var content = cell.defaultContentConfiguration()
                content.text = item.name
                cell.contentConfiguration = content
                cell.accessoryType = .none
            },
            filterHandler: { item, searchText in
                item.name.lowercased().contains(searchText.lowercased())
            }
        )
        selection.title = R.string.global.receiptTypes()
        selection.onSelect = { [weak self] type in
            self?.selectedType = type.name
            self?.updateHeader()
        }

        let nav = UINavigationController(rootViewController: selection)
        nav.modalPresentationStyle = .popover
        if let pop = nav.popoverPresentationController {
            pop.sourceView = typeFieldView
            pop.sourceRect = typeFieldView.bounds
            pop.permittedArrowDirections = [.up, .down]
            pop.delegate = self
        }
        present(nav, animated: true)
    }

    @objc private func saveAction() {
        let cash = cashInputContainer.text
        let card = cardInputContainer.text
        let note = noteInputContainer.text
        viewModel.save(
            date: selectedDate,
            type: selectedType,
            cash: cash,
            card: card,
            note: note,
            ignoreStockWarning: false
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSaveResult(result)
            }
        }
    }

    private func handleSaveResult(_ result: Result<Void, OrderSaveError>) {
        switch result {
        case .success:
            onSave?()
            navigationController?.parent?.navigationController?.popToRootViewController(animated: true)
        case .failure(let error):
            switch error {
            case .stockValidationFailed(let warnings):
                showStockWarning(warnings)
            case .saveFailed, .fetchFailed:
                let alert = UIAlertController(
                    title: R.string.global.error(),
                    message: R.string.global.somethingWentWrong(),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: R.string.global.actionOk(), style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func showStockWarning(_ warnings: [StockWarning]) {
        let message = warnings.map { warning in
            let shortage = warning.requiredQty - warning.currentStock
            return "\(warning.ingredientName): Need \(String(format: "%.2f", shortage)) more"
        }.joined(separator: "\n")

        let alert = UIAlertController(
            title: "Stock Warning",
            message: "Not enough stock for:\n" + message + "\nProceed anyway?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel, handler: nil))
        alert.addAction(
            UIAlertAction(
                title: "Proceed",
                style: .destructive,
                handler: { [weak self] _ in
                    guard let self else { return }
                    self.viewModel.save(
                        date: self.selectedDate,
                        type: self.selectedType,
                        cash: self.cashInputContainer.text,
                        card: self.cardInputContainer.text,
                        note: self.noteInputContainer.text,
                        ignoreStockWarning: true
                    ) { [weak self] result in
                        DispatchQueue.main.async {
                            self?.handleSaveResult(result)
                        }
                    }
                }
            )
        )
        present(alert, animated: true)
    }

    @objc private func stepperValueChanged(_ stepper: UIStepper) {
        let stepperValue = Int(stepper.value)
        let stepperTag = Int(stepper.tag)
        viewModel.productsViewModel.setQuantity(tag: stepperTag, quantity: stepperValue)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let current = textField.text ?? ""
        if current == "0" || current == "0,0" || current == "0.0" { textField.text = "" }
    }
}

extension OrderReceiptPadViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard
            let item = dataSource?.itemIdentifier(for: indexPath),
            let index = viewModel.productsViewModel.index(forProductId: item.productId)
        else { return nil }

        let delete = UIContextualAction(
            style: .destructive,
            title: R.string.global.delete()
        ) { [weak self] _, _, completion in
            self?.viewModel.productsViewModel.setQuantity(tag: index, quantity: 0)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

extension OrderReceiptPadViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController
    ) {
        dateFieldView.setHighlightedState(false)
        typeFieldView.setHighlightedState(false)
    }
}
