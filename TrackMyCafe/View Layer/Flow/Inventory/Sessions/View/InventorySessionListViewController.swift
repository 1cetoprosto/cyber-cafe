//
//  InventorySessionListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 26.08.2026.
//

import TinyConstraints
import UIKit

final class InventorySessionListViewController: UIViewController, ProGated {

    // MARK: - Properties

    private let viewModel: InventorySessionListViewModelProtocol

    private lazy var tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.register(
            InventorySessionCell.self, forCellReuseIdentifier: "InventorySessionCell"
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
        label.text = R.string.global.inventorySessionsEmptyState()
        label.isHidden = true
        return label
    }()

    // MARK: - Init

    init(viewModel: InventorySessionListViewModelProtocol = InventorySessionListViewModel()) {
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
        title = R.string.global.inventorySessionsTitle()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleNewSession)
        )

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
                let hasItems = !self.viewModel.items.isEmpty
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

    @objc private func handleNewSession() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let vm = BulkSessionViewModel()
            let vc = BulkSessionViewController(viewModel: vm)
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true)
        }
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

extension InventorySessionListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InventorySessionCell", for: indexPath
        ) as? InventorySessionCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            guard let sessionId = self.viewModel.sessionId(at: indexPath) else { return }

            let filteredVM = InventoryAdjustmentListViewModel()
            filteredVM.setFilter(bulkSessionId: sessionId)

            let detailVC = InventoryAdjustmentListViewController(viewModel: filteredVM)
            detailVC.title = R.string.global.inventoryAdjustmentJournalTitle()
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}
