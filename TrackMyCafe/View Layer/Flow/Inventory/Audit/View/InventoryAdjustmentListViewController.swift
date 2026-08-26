//
//  InventoryAdjustmentListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 25.08.2026.
//

import TinyConstraints
import UIKit

final class InventoryAdjustmentListViewController: UIViewController, ProGated {

    // MARK: - Properties

    private let viewModel: InventoryAdjustmentListViewModelProtocol

    private lazy var tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.register(
            InventoryAdjustmentCell.self, forCellReuseIdentifier: "InventoryAdjustmentCell"
        )
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

    private let emptyStateLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .center
        label.text = R.string.global.inventoryAuditEmptyState()
        label.isHidden = true
        return label
    }()

    // MARK: - Init

    init(viewModel: InventoryAdjustmentListViewModelProtocol = InventoryAdjustmentListViewModel()) {
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.inventoryAdjustmentJournalTitle()

        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)

        tableView.edgesToSuperview()
        activityIndicator.centerInSuperview()

        emptyStateLabel.leadingToSuperview(offset: 32)
        emptyStateLabel.trailingToSuperview(offset: -32)
        emptyStateLabel.centerYToSuperview(offset: -16)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func bindViewModel() {
        var vm = viewModel

        vm.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
                let hasItems = !self.viewModel.sections.isEmpty
                self.emptyStateLabel.isHidden = hasItems
            }
        }

        vm.isLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
        }

        vm.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showError(message: message)
            }
        }
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.fetchData()
    }

    private func showError(message: String) {
        PopupFactory.showPopup(
            title: R.string.global.error(),
            description: message,
            buttonAction: nil
        )
    }
}

// MARK: - UITableViewDataSource & Delegate

extension InventoryAdjustmentListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDate = viewModel.sections[section].date
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: sectionDate)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "InventoryAdjustmentCell", for: indexPath
            ) as? InventoryAdjustmentCell
        else {
            return UITableViewCell()
        }
        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let adjustment = viewModel.adjustment(at: indexPath) else { return }
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let detailVM = InventoryAdjustmentDetailViewModel(adjustment: adjustment)
            let detailVC = InventoryAdjustmentDetailViewController(viewModel: detailVM)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
