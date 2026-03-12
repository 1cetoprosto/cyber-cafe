//
//  PurchaseListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import TinyConstraints
import UIKit

class PurchaseListViewController: UIViewController, ProGated {

    private let viewModel: PurchaseListViewModelType

    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(
            PurchaseTableViewCell.self, forCellReuseIdentifier: PurchaseTableViewCell.identifier)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .singleLine
        return tableView
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()

    private var selectedStartDate: Date?
    private var selectedEndDate: Date?
    private var selectedIngredientId: String?

    // MARK: - Init
    init(viewModel: PurchaseListViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }

    // MARK: - Setup
    private func setupUI() {
        // title = R.string.global.purchases() // Managed by parent
        view.backgroundColor = UIColor.Main.background
        view.addSubview(tableView)

        let addItem = UIBarButtonItem(customView: addButton)
        let filterItem = UIBarButtonItem(customView: filterButton)
        navigationItem.rightBarButtonItems = [addItem, filterItem]
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupConstraints() {
        tableView.edgesToSuperview(usingSafeArea: true)
    }

    private func fetchData() {
        viewModel.getPurchases { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let createVM = CreatePurchaseViewModel()
            let createVC = CreatePurchaseViewController(viewModel: createVM)
            self.navigationController?.pushViewController(createVC, animated: true)
        }
    }

    @objc private func filterButtonTapped() {
        let alert = UIAlertController(
            title: R.string.global.filtersTitle(),
            message: nil,
            preferredStyle: .actionSheet
        )

        let dateFilterAction = UIAlertAction(
            title: R.string.global.filterByDate(),
            style: .default
        ) { [weak self] _ in
            self?.showDateRangePicker()
        }

        let ingredientFilterAction = UIAlertAction(
            title: R.string.global.filterByIngredient(),
            style: .default
        ) { [weak self] _ in
            self?.presentIngredientFilter()
        }

        let clearFiltersAction = UIAlertAction(
            title: R.string.global.clearFilters(),
            style: .destructive
        ) { [weak self] _ in
            self?.selectedStartDate = nil
            self?.selectedEndDate = nil
            self?.selectedIngredientId = nil
            self?.applyFilters()
        }

        let cancelAction = UIAlertAction(
            title: R.string.global.cancel(),
            style: .cancel
        )

        alert.addAction(dateFilterAction)
        alert.addAction(ingredientFilterAction)
        alert.addAction(clearFiltersAction)
        alert.addAction(cancelAction)

        if let popover = alert.popoverPresentationController {
            popover.sourceView = filterButton
            popover.sourceRect = filterButton.bounds
            popover.permittedArrowDirections = .any
        }

        present(alert, animated: true)
    }

    private func showDateRangePicker() {
        let vc = DateRangePickerViewController()
        vc.initialStartDate = selectedStartDate
        vc.initialEndDate = selectedEndDate
        vc.onApply = { [weak self] start, end in
            guard let self = self else { return }
            self.selectedStartDate = Calendar.current.startOfDay(for: start)
            let endOfDay =
            Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
            self.selectedEndDate = endOfDay
            self.applyFilters()
        }
        vc.onCancel = {}
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    private func presentIngredientFilter() {
        viewModel.getPurchases { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(
                title: R.string.global.filterByIngredient(),
                message: nil,
                preferredStyle: .actionSheet
            )
            let items = self.viewModel.availableIngredients()
            for item in items {
                let action = UIAlertAction(
                    title: item.name,
                    style: .default
                ) { [weak self] _ in
                    self?.selectedIngredientId = item.id
                    self?.applyFilters()
                }
                alert.addAction(action)
            }
            let cancelAction = UIAlertAction(
                title: R.string.global.cancel(),
                style: .cancel
            )
            alert.addAction(cancelAction)
            DispatchQueue.main.async {
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = self.filterButton
                    popover.sourceRect = self.filterButton.bounds
                    popover.permittedArrowDirections = .any
                }
                self.present(alert, animated: true)
            }
        }
    }

    private func collectIngredientIds() -> [String] {
        var ids: [String] = []
        let sections = viewModel.numberOfSections()
        for section in 0..<sections {
            let rows = viewModel.numberOfRowInSection(for: section)
            for row in 0..<rows {
                let indexPath = IndexPath(row: row, section: section)
                let purchase = viewModel.purchase(at: indexPath)
                ids.append(purchase.ingredientId)
            }
        }
        return ids
    }

    private func applyFilters() {
        let range: ClosedRange<Date>?
        if let start = selectedStartDate, let end = selectedEndDate {
            range = start...end
        } else {
            range = nil
        }

        viewModel.applyFilter(
            dateRange: range,
            ingredientId: selectedIngredientId
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}

private final class DateRangePickerViewController: UIViewController {
    var onApply: ((Date, Date) -> Void)?
    var onCancel: (() -> Void)?
    var initialStartDate: Date?
    var initialEndDate: Date?

    private var startDate: Date = Date()
    private var endDate: Date = Date()
    private let modeControl: UISegmentedControl = {
        let c = UISegmentedControl(items: [R.string.global.dateFrom(), R.string.global.dateTo()])
        c.selectedSegmentIndex = 0
        return c
    }()
    private let picker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .date
        p.preferredDatePickerStyle = .wheels
        return p
    }()
    private let applyButton: UIButton = {
        let b = DefaultButton()
        b.setTitle(R.string.global.actionOk(), for: .normal)
        return b
    }()
    private let cancelButton: UIButton = {
        let b = DefaultButton()
        b.setTitle(R.string.global.cancel(), for: .normal)
        return b
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = UIColor.Main.text
        l.applyDynamic(Typography.title3DemiBold)
        l.text = R.string.global.filterByDate()
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIConstants.standardPadding
        stack.distribution = .fill
        stack.alignment = .fill

        view.addSubview(stack)
        stack.topToSuperview(offset: UIConstants.standardPadding, usingSafeArea: true)
        stack.leadingToSuperview(offset: UIConstants.standardPadding)
        stack.trailingToSuperview(offset: UIConstants.standardPadding)
        stack.bottomToSuperview(offset: -UIConstants.standardPadding, relation: .equalOrGreater)

        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.spacing = UIConstants.standardPadding
        buttons.distribution = .fillEqually

        buttons.addArrangedSubview(cancelButton)
        buttons.addArrangedSubview(applyButton)

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(modeControl)
        stack.addArrangedSubview(picker)
        stack.addArrangedSubview(buttons)

        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        startDate = initialStartDate ?? Calendar.current.startOfDay(for: Date())
        endDate = initialEndDate ?? Date()
        picker.date = startDate
    }

    @objc private func applyTapped() {
        onApply?(startDate, endDate)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }

    @objc private func modeChanged() {
        if modeControl.selectedSegmentIndex == 0 {
            picker.date = startDate
        } else {
            picker.date = endDate
        }
    }

    @objc private func dateChanged() {
        if modeControl.selectedSegmentIndex == 0 {
            startDate = picker.date
        } else {
            endDate = picker.date
        }
    }
}

// MARK: - UITableViewDataSource
extension PurchaseListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowInSection(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: PurchaseTableViewCell.identifier, for: indexPath)
                as? PurchaseTableViewCell,
            let cellVM = viewModel.cellViewModel(for: indexPath)
        else {
            return UITableViewCell()
        }

        cell.configure(with: cellVM)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeaderInSection(for: section)
    }
}

// MARK: - UITableViewDelegate
extension PurchaseListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let purchase = viewModel.purchase(at: indexPath)
        let createVM = CreatePurchaseViewModel(purchaseToEdit: purchase)
        let createVC = CreatePurchaseViewController(viewModel: createVM)
        navigationController?.pushViewController(createVC, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
