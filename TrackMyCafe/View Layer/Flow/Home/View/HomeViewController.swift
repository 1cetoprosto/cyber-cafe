import SVProgressHUD
import TinyConstraints
import UIKit

final class HomeViewController: UIViewController, ProGated {
    private let viewModel: HomeViewModelType = HomeViewModel()
    private var lastHeaderWidth: CGFloat = 0
    private var currentPeriod: DashboardPeriod = .month

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor.Main.background
        tv.separatorStyle = .none
        tv.register(
            TransactionTableViewCell.self,
            forCellReuseIdentifier: TransactionTableViewCell.identifier)
        return tv
    }()

    private lazy var headerView = HomeHeaderView()
    private let headerContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.home()
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView.dataSource = self
        tableView.delegate = self

        headerView.onAddIncome = { [weak self] in self?.openAddIncome() }
        headerView.onAddExpense = { [weak self] in self?.openAddExpense() }
        headerView.onPeriodChanged = { [weak self] idx in
            self?.applyPeriodChange(index: idx)
        }
        headerView.onManualOperations = { [weak self] in
            self?.openManualOperations()
        }
        headerView.onDeleteDemoData = { [weak self] in
            self?.confirmDeleteDemoData()
        }

        view.addSubview(tableView)
        tableView.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardSpacing,
                left: UIConstants.standardSpacing,
                bottom: 0,
                right: UIConstants.standardSpacing
            ),
            usingSafeArea: true
        )

        Task { await loadData() }

        NotificationCenter.default.addObserver(
            self, selector: #selector(dataDidUpdate), name: NSNotification.Name("DataDidUpdate"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeCategoryDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dataDidUpdate() {
        Task { await loadData() }
    }

    @objc private func contentSizeCategoryDidChange() {
        setTableHeaderSized()
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        Task { await loadData() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = tableView.bounds.width
        if width != lastHeaderWidth || tableView.tableHeaderView == nil {
            setTableHeaderSized()
            lastHeaderWidth = width
        }
    }

    private func setTableHeaderSized() {
        let width = tableView.bounds.width
        guard width > 0 else { return }

        headerContainer.backgroundColor = UIColor.Main.background
        if headerView.superview !== headerContainer {
            headerContainer.addSubview(headerView)
            headerView.edgesToSuperview()
        }
        headerContainer.layoutIfNeeded()

        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = headerContainer.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = headerContainer
    }

    @MainActor
    private func loadData() async {
        await viewModel.loadDashboard()
        configureHeader(for: currentPeriod)
        setTableHeaderSized()
        tableView.reloadData()
    }

    private func openAddIncome() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let mode = SettingsManager.shared.loadOrderEntryMode()
            if UIDevice.isIpad, traitCollection.horizontalSizeClass == .regular, mode == .perOrder {
                let split = OrderSplitContainerViewController()
                split.onSave = { [weak self] in self?.reloadAfterAction() }
                split.hidesBottomBarWhenPushed = true
                if let nav = self.navigationController {
                    nav.pushViewController(split, animated: true)
                } else {
                    split.modalPresentationStyle = .fullScreen
                    self.present(split, animated: true)
                }
            } else {
                let vc = OrderDetailsViewController()
                vc.onSave = { [weak self] in self?.reloadAfterAction() }
                if let nav = self.navigationController {
                    nav.pushViewController(vc, animated: true)
                } else {
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            }
        }
    }

    private func openAddExpense() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let empty = OpexExpenseModel(
                id: "", date: Date(), categoryId: "General", amount: 0, note: ""
            )
            let vm = CostDetailsViewModel(cost: empty, dataService: DomainCostDataService())
            let vc = CostDetailsListViewController(viewModel: vm)
            vc.onSave = { [weak self] in self?.reloadAfterAction() }
            vc.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func reloadAfterAction() {
        Task { await loadData() }
    }

    private func openManualOperations() {
        checkProOrShowPaywall { [weak self] in
            guard let self else { return }
            let viewModel = ManualMovementListViewModel(
                service: DomainManualMovementService()
            )
            let vc = ManualMovementListViewController(viewModel: viewModel)
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func confirmDeleteDemoData() {
        let alert = UIAlertController(
            title: R.string.global.deleteDemoDataTitle(),
            message: R.string.global.deleteDemoDataMessage(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel))
        alert.addAction(
            UIAlertAction(title: R.string.global.delete(), style: .destructive) { _ in
                SVProgressHUD.show(withStatus: R.string.global.deleting())
                DemoDataManager.shared.deleteDemoData { success in
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        if success {
                            SVProgressHUD.showSuccess(withStatus: R.string.global.actionDone())
                            self.reloadAfterAction()
                        } else {
                            SVProgressHUD.showError(withStatus: R.string.global.error())
                        }
                    }
                }
            })
        present(alert, animated: true)
    }

    private func applyPeriodChange(index: Int) {
        let period: DashboardPeriod
        switch index {
        case 0: period = .day
        case 1: period = .week
        default: period = .month
        }
        currentPeriod = period
        viewModel.setPeriod(period)
        configureHeader(for: period)
        setTableHeaderSized()
        tableView.reloadData()
    }

    private func configureHeader(for period: DashboardPeriod) {
        let sales: Double
        switch period {
        case .day:
            sales = viewModel.todaySum
        case .week:
            sales = viewModel.weekSum
        case .month:
            sales = viewModel.monthSum
        }
        headerView.configure(
            date: viewModel.dateToday,
            period: period,
            sales: sales,
            expenses: viewModel.periodExpenses,
            profit: viewModel.periodProfit,
            cash: viewModel.cashBalance,
            card: viewModel.cardBalance,
            showDeleteDemoData: DemoDataManager.shared.isDemoDataPresent
        )
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 0 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
}
