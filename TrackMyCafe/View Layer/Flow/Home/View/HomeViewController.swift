import TinyConstraints
import UIKit

final class HomeViewController: UIViewController {
  private let viewModel: HomeViewModelType = HomeViewModel()

  private let tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .plain)
    tv.backgroundColor = UIColor.Main.background
    tv.separatorStyle = .none
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(
      TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.identifier)
    return tv
  }()

  private let headerView = HomeHeaderView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.Main.background
    title = ""
    navigationItem.largeTitleDisplayMode = .never
    navigationController?.navigationBar.prefersLargeTitles = false

    tableView.dataSource = self
    tableView.delegate = self

    headerView.onAddIncome = { [weak self] in self?.openAddIncome() }
    headerView.onAddExpense = { [weak self] in self?.openAddExpense() }

    view.addSubview(tableView)
    tableView.edgesToSuperview(insets: .init(top: 10, left: 10, bottom: 0, right: 10))

    Task { await loadData() }
  }

  private func setTableHeaderSized() {
    headerView.layoutIfNeeded()
    let targetSize = CGSize(
      width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
    let height = headerView.systemLayoutSizeFitting(targetSize).height
    headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
    tableView.tableHeaderView = headerView
  }

  @MainActor
  private func loadData() async {
    await viewModel.loadDashboard()
    headerView.configure(
      date: viewModel.dateToday,
      today: viewModel.todaySum,
      week: viewModel.weekSum,
      month: viewModel.monthSum,
      expenses: viewModel.monthExpenses,
      profit: viewModel.monthProfit
    )
    setTableHeaderSized()
    tableView.reloadData()
  }

  private func openAddIncome() {
    let vc = OrderDetailsViewController()
    vc.onSave = { [weak self] in self?.reloadAfterAction() }
    navigationController?.pushViewController(vc, animated: true)
  }

  private func openAddExpense() {
    let empty = CostModel(id: "", date: Date(), name: "", sum: 0)
    let vm = CostDetailsViewModel(cost: empty, dataService: DomainCostDataService())
    let vc = CostDetailsListViewController(viewModel: vm)
    vc.modalPresentationStyle = .fullScreen
    navigationController?.pushViewController(vc, animated: true)
  }

  private func reloadAfterAction() {
    Task { await loadData() }
  }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int { 2 }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let container = UIView()
    container.backgroundColor = UIColor.Main.background
    let title = UILabel()
    title.applyDynamic(Typography.title3DemiBold)
    title.textColor = UIColor.Main.text
    title.text = section == 0 ? R.string.global.recentIncomes() : R.string.global.recentExpenses()
    let button = UIButton(type: .system)
    button.setTitle(R.string.global.allArrow(), for: .normal)
    button.setTitleColor(UIColor.systemGreen, for: .normal)
    button.titleLabel?.font = Typography.footnote
    button.addTarget(
      self, action: section == 0 ? #selector(openIncomeList) : #selector(openCostList),
      for: .touchUpInside)
    container.addSubview(title)
    container.addSubview(button)
    title.translatesAutoresizingMaskIntoConstraints = false
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(
        equalTo: container.leadingAnchor, constant: UIConstants.standardPadding),
      title.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      button.trailingAnchor.constraint(
        equalTo: container.trailingAnchor, constant: -UIConstants.standardPadding),
      button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
    return container
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    44
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
      cell.configure(title: item.name, date: item.date, amount: item.sum, isIncome: false)
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
}
