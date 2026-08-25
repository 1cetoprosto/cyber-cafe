//
//  InventoryAdjustmentDetailViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import TinyConstraints
import UIKit

final class InventoryAdjustmentDetailViewController: UIViewController {

    // MARK: - Views

    private let headerView = UIView()

    private let titleLabel: AppLabel = {
        let label = AppLabel(style: .title3)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 2
        return label
    }()

    private let deltaLabel: AppLabel = {
        let label = AppLabel(style: .title1)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    private let viewModel: InventoryAdjustmentDetailViewModelProtocol

    // MARK: - Init

    init(viewModel: InventoryAdjustmentDetailViewModelProtocol) {
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
        bindViewModel()
        viewModel.loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.inventoryAdjustmentDetailTitle()

        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        headerView.addSubview(titleLabel)
        headerView.addSubview(deltaLabel)

        headerView.topToSuperview(offset: 0, usingSafeArea: true)
        headerView.leadingToSuperview()
        headerView.trailingToSuperview()

        titleLabel.topToSuperview(offset: 16)
        titleLabel.leadingToSuperview(offset: UIConstants.standardPadding)
        titleLabel.trailingToSuperview(offset: -UIConstants.standardPadding)

        deltaLabel.topToBottom(of: titleLabel, offset: 8)
        deltaLabel.leadingToSuperview(offset: UIConstants.standardPadding)
        deltaLabel.trailingToSuperview(offset: -UIConstants.standardPadding)
        deltaLabel.bottomToSuperview(offset: -16)

        tableView.topToBottom(of: headerView)
        tableView.leadingToSuperview()
        tableView.trailingToSuperview()
        tableView.bottomToSuperview()

        activityIndicator.centerInSuperview()

        tableView.register(
            InventoryAdjustmentDetailRowCell.self,
            forCellReuseIdentifier: "InventoryAdjustmentDetailRowCell"
        )
    }

    private func bindViewModel() {
        var vm = viewModel

        vm.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.titleLabel.text = self.viewModel.ingredientName
                self.deltaLabel.text = self.viewModel.deltaText
                self.deltaLabel.textColor =
                    self.viewModel.deltaIsPositive
                    ? .systemGreen
                    : .systemRed
                self.tableView.reloadData()
            }
        }

        vm.onError = { [weak self] message in
            DispatchQueue.main.async {
                PopupFactory.showPopup(
                    title: R.string.global.error(),
                    description: message,
                    buttonAction: nil
                )
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension InventoryAdjustmentDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "InventoryAdjustmentDetailRowCell", for: indexPath
            ) as? InventoryAdjustmentDetailRowCell
        else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.rows[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - Row Cell

final class InventoryAdjustmentDetailRowCell: BaseListTableViewCell {

    private let titleLabel: AppLabel = {
        let label = AppLabel(style: .callout)
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 1
        return label
    }()

    private let valueLabel: AppLabel = {
        let label = AppLabel(style: .body)
        label.textColor = UIColor.TableView.cellLabel
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func setupUI() {
        selectionStyle = .none

        let root = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        root.axis = .horizontal
        root.alignment = .top
        root.distribution = .fill
        root.spacing = UIConstants.standardSpacing

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentView.addSubview(root)
        root.edgesToSuperview(
            insets: .init(
                top: UIConstants.smallSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.smallSpacing,
                right: UIConstants.standardPadding
            )
        )
    }

    func configure(with row: InventoryAdjustmentDetailRow) {
        titleLabel.text = row.title
        valueLabel.text = row.value
    }
}
