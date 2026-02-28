import TinyConstraints
import SVProgressHUD
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
            TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.identifier)
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
            )
        )
        
        Task { await loadData() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidUpdate), name: NSNotification.Name("DataDidUpdate"), object: nil)
    }
    
    @objc private func dataDidUpdate() {
        Task { await loadData() }
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
        guard checkProOrShowPaywall() else { return }
        let vc = OrderDetailsViewController()
        vc.onSave = { [weak self] in self?.reloadAfterAction() }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openAddExpense() {
        guard checkProOrShowPaywall() else { return }
        let empty = OpexExpenseModel(
            id: "", date: Date(), categoryId: "General", amount: 0, note: ""
        )
        let vm = CostDetailsViewModel(cost: empty, dataService: DomainCostDataService())
        let vc = CostDetailsListViewController(viewModel: vm)
        vc.onSave = { [weak self] in self?.reloadAfterAction() }
        vc.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func reloadAfterAction() {
        Task { await loadData() }
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
            expenses: viewModel.monthExpenses,
            profit: viewModel.monthProfit,
            cash: viewModel.cashBalance,
            card: viewModel.cardBalance,
            showDeleteDemoData: DemoDataManager.shared.isDemoDataPresent
        )
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titleText =
        section == 0 ? R.string.global.recentIncomes() : R.string.global.recentExpenses()
        let action = section == 0 ? #selector(openIncomeList) : #selector(openCostList)
        return makeSectionHeader(title: titleText, action: action)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UIConstants.tableSectionHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? viewModel.lastIncome.count : viewModel.lastExpense.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: TransactionTableViewCell.identifier, for: indexPath)
                as? TransactionTableViewCell
        else { return UITableViewCell() }
        if indexPath.section == 0 {
            let item = viewModel.lastIncome[indexPath.row]
            cell.configure(title: item.type, date: item.date, amount: item.sum, isIncome: true)
        } else {
            let item = viewModel.lastExpense[indexPath.row]
            cell.configure(title: item.note ?? "", date: item.date, amount: item.amount, isIncome: false)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            navigationController?.pushViewController(OrderListViewController(), animated: true)
        } else {
            navigationController?.pushViewController(CostListViewController(), animated: true)
        }
    }
    
    @objc private func openIncomeList() {
        navigationController?.pushViewController(OrderListViewController(), animated: true)
    }
    @objc private func openCostList() {
        navigationController?.pushViewController(CostListViewController(), animated: true)
    }
    
    private func makeSectionHeader(title: String, action: Selector) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.Main.background
        let titleLabel = UILabel()
        titleLabel.applyDynamic(Typography.title3DemiBold)
        titleLabel.textColor = UIColor.Main.text
        titleLabel.text = title
        let button = UIButton(type: .system)
        button.setTitle(R.string.global.allArrow(), for: .normal)
        button.setTitleColor(Theme.current.tabBarUnselectedTint, for: .normal)
        button.titleLabel?.font = Typography.body
        button.addTarget(self, action: action, for: .touchUpInside)
        container.addSubview(titleLabel)
        container.addSubview(button)
        titleLabel.leadingToSuperview(offset: UIConstants.standardSpacing)
        titleLabel.centerYToSuperview()
        button.trailingToSuperview(offset: UIConstants.standardSpacing)
        button.centerYToSuperview()
        return container
    }
}
