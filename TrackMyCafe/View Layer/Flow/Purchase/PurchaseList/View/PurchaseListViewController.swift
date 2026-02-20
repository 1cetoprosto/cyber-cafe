//
//  PurchaseListViewController.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 10.02.2026.
//

import UIKit
import TinyConstraints

class PurchaseListViewController: UIViewController {

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
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

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
        title = R.string.global.purchases()
        view.backgroundColor = UIColor.Main.background
        view.addSubview(tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
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
        let createVM = CreatePurchaseViewModel()
        let createVC = CreatePurchaseViewController(viewModel: createVM)
        navigationController?.pushViewController(createVC, animated: true)
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
