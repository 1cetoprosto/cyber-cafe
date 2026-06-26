import TinyConstraints
import UIKit

final class ManualMovementListViewController: UIViewController, ProGated {
    private let viewModel: ManualMovementListViewModelType

    private let tableView = UITableView.standardList()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

    init(viewModel: ManualMovementListViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.manualOperations()
        view.backgroundColor = UIColor.Main.background

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            ManualMovementTableViewCell.self,
            forCellReuseIdentifier: ManualMovementTableViewCell.reuseIdentifier
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)

        view.addSubview(tableView)
        tableView.edgesToSuperview(usingSafeArea: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await reload() }
    }

    @objc private func addButtonTapped() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let vm = ManualMovementEditViewModel(
                operationToEdit: nil,
                service: DomainManualMovementService()
            )
            let vc = ManualMovementEditViewController(viewModel: vm)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func reload() async {
        await viewModel.reload()
        await MainActor.run { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("error", tableName: "Global", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("actionOk", tableName: "Global", comment: ""), style: .default)
        )
        present(alert, animated: true)
    }
}

extension ManualMovementListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRowsInSection(section)
    }

    func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        viewModel.titleForHeaderInSection(section)
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ManualMovementTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? ManualMovementTableViewCell
        else {
            return UITableViewCell()
        }

        let operation = viewModel.operation(at: indexPath)
        cell.configure(with: operation)
        return cell
    }
}

extension ManualMovementListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let operation = viewModel.operation(at: indexPath)

        let vm = ManualMovementEditViewModel(
            operationToEdit: operation,
            service: DomainManualMovementService()
        )
        let vc = ManualMovementEditViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteTitle = NSLocalizedString("delete", tableName: "Global", comment: "")
        let action = UIContextualAction(style: .destructive, title: deleteTitle) { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            Task {
                do {
                    try await self.viewModel.delete(at: indexPath)
                    await MainActor.run {
                        tableView.reloadData()
                        completion(true)
                    }
                } catch {
                    await MainActor.run {
                        self.showError(error.localizedDescription)
                        completion(false)
                    }
                }
            }
        }
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(
        _ tableView: UITableView,
        willDisplayHeaderView view: UIView,
        forSection section: Int
    ) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Typography.footnote
        header.textLabel?.textColor = UIColor.Main.text
        if #available(iOS 11.0, *) {
            header.textLabel?.adjustsFontForContentSizeCategory = true
        }
    }
}
