import TinyConstraints
import UIKit

final class ReportsHubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    Loggable
{

    private let viewModel: ReportsHubViewModelType

    private let segmentedControl: UISegmentedControl = {
        let items = [
            R.string.global.commonDay(),
            R.string.global.commonWeek(),
            R.string.global.commonMonth(),
        ]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentTintColor = Theme.current.tabBarTint
        control.setTitleTextAttributes(
            [.foregroundColor: Theme.current.primaryText, .font: Typography.bodyMedium],
            for: .normal)
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: Typography.bodyBold],
            for: .selected)
        return control
    }()

    private let periodInfoLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body
        label.textColor = Theme.current.secondaryText
        label.textAlignment = .center
        return label
    }()

    // MARK: - Hero KPI Card (at-a-glance truth)

    private let heroCardView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.cellBackground
        v.layer.cornerRadius = UIConstants.mediumCornerRadius
        return v
    }()

    private let heroNetTitleLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnote
        l.textColor = Theme.current.secondaryText
        l.numberOfLines = 1
        l.text = R.string.global.kpiBigNet()
        return l
    }()

    private let heroNetValueLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.largeTitleBold
        l.textColor = Theme.current.primaryText
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.6
        l.numberOfLines = 1
        l.setContentHuggingPriority(.defaultLow, for: .vertical)
        return l
    }()

    private let heroSalesTitleLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnoteLight
        l.textColor = Theme.current.secondaryText
        l.text = R.string.global.hubBigSalesLabel()
        l.numberOfLines = 1
        return l
    }()

    private let heroSalesValueLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.calloutDemi
        l.textColor = Theme.current.primaryText
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.numberOfLines = 1
        return l
    }()

    private let heroCostsTitleLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnoteLight
        l.textColor = Theme.current.secondaryText
        l.text = R.string.global.hubBigCostsLabel()
        l.numberOfLines = 1
        return l
    }()

    private let heroCostsValueLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.calloutDemi
        l.textColor = .systemOrange
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.numberOfLines = 1
        return l
    }()

    private let tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            ReportsHubReportCell.self,
            forCellReuseIdentifier: ReportsHubReportCell.identifier
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        return tableView
    }()

    init(viewModel: ReportsHubViewModelType = ReportsHubViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.current.primaryBackground
        title = R.string.global.reportsTitle()
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.delegate = self
        tableView.dataSource = self

        setupLayout()
        bindViewModel()
        apply(viewModel.currentPeriod)
    }

    private func setupLayout() {
        // Hero card subviews
        heroCardView.addSubview(heroNetTitleLabel)
        heroCardView.addSubview(heroNetValueLabel)

        let salesSV = UIStackView(arrangedSubviews: [heroSalesTitleLabel, heroSalesValueLabel])
        salesSV.axis = .vertical
        salesSV.spacing = 2

        let costsSV = UIStackView(arrangedSubviews: [heroCostsTitleLabel, heroCostsValueLabel])
        costsSV.axis = .vertical
        costsSV.spacing = 2

        let bottomSV = UIStackView(arrangedSubviews: [salesSV, costsSV])
        bottomSV.axis = .horizontal
        bottomSV.distribution = .fillEqually
        bottomSV.spacing = UIConstants.smallSpacing

        heroCardView.addSubview(bottomSV)

        heroNetTitleLabel.topToSuperview(offset: UIConstants.smallSpacing)
        heroNetTitleLabel.leftToSuperview(offset: UIConstants.standardPadding)
        heroNetTitleLabel.rightToSuperview(offset: -UIConstants.standardPadding)

        heroNetValueLabel.topToBottom(of: heroNetTitleLabel, offset: 4)
        heroNetValueLabel.left(to: heroNetTitleLabel)
        heroNetValueLabel.right(to: heroNetTitleLabel)

        bottomSV.topToBottom(of: heroNetValueLabel, offset: UIConstants.smallSpacing)
        bottomSV.left(to: heroNetTitleLabel)
        bottomSV.right(to: heroNetTitleLabel)
        bottomSV.bottomToSuperview(offset: -UIConstants.smallSpacing)

        // Header: segmented + period + hero card
        let headerStack = UIStackView(arrangedSubviews: [
            segmentedControl,
            periodInfoLabel,
            heroCardView,
        ])
        headerStack.axis = .vertical
        headerStack.spacing = UIConstants.mediumSpacing
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(
            top: UIConstants.smallSpacing,
            left: UIConstants.standardPadding,
            bottom: UIConstants.mediumSpacing,
            right: UIConstants.standardPadding
        )

        headerStack.frame = CGRect(
            x: 0, y: 0,
            width: view.bounds.width,
            height: 250
        )
        tableView.tableHeaderView = headerStack

        view.addSubview(tableView)
        tableView.edgesToSuperview(usingSafeArea: true)

        segmentedControl.addTarget(
            self,
            action: #selector(segmentChanged),
            for: .valueChanged
        )
    }

    private func bindViewModel() {
        viewModel.onPeriodChanged = { [weak self] in
            guard let self = self else { return }
            self.apply(self.viewModel.currentPeriod)
        }
    }

    private func apply(_ period: DashboardPeriod) {
        segmentedControl.selectedSegmentIndex = viewModel.segmentIndex(for: period)
        periodInfoLabel.text = periodDescription(for: period)
        tableView.reloadData()
        loadHeroCard(for: period)
    }

    private func loadHeroCard(for period: DashboardPeriod) {
        // skeleton until real data
        let currency = R.string.global.commonCurrencyUAH()
        heroSalesValueLabel.text = Self.currencyString(value: 0, currency: currency)
        heroCostsValueLabel.text = Self.currencyString(value: 0, currency: currency)
        heroNetValueLabel.text = Self.currencyString(value: 0, currency: currency)
        heroNetValueLabel.textColor = Theme.current.primaryText

        Task { @MainActor in
            let report = await viewModel.buildPLReport()
            applyHeroCard(
                sales: report.sales,
                totalCosts: report.cogs + report.opex,
                netProfit: report.netProfit,
                currency: currency
            )
        }
    }

    private func applyHeroCard(
        sales: Double,
        totalCosts: Double,
        netProfit: Double,
        currency: String
    ) {
        heroSalesValueLabel.text = Self.currencyString(value: sales, currency: currency)
        heroCostsValueLabel.text = Self.currencyString(value: totalCosts, currency: currency)
        heroNetValueLabel.text = Self.currencyString(value: netProfit, currency: currency)
        heroNetValueLabel.textColor = netProfit >= 0 ? .systemGreen : .systemRed
    }

    private static func currencyString(value: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = currency
        f.maximumFractionDigits = 0
        return f.string(for: value) ?? "0"
    }

    private func periodDescription(for period: DashboardPeriod) -> String {
        let formatter = DateFormatter()
        let now = Date()
        switch period {
        case .day:
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: now)
        case .week:
            let interval = period.interval(for: now)
            formatter.dateFormat = "d MMM"
            return
                "\(formatter.string(from: interval.start)) – \(formatter.string(from: interval.end))"
        case .month:
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: now)
        }
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        viewModel.selectPeriod(at: sender.selectedSegmentIndex)
    }

    // MARK: - Table View

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfReports
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: ReportsHubReportCell.identifier,
                for: indexPath) as! ReportsHubReportCell
        let item = viewModel.report(at: indexPath.row)
        let title = item.title()
        let subtitle = item.subtitle()
        cell.configure(kind: item.kind, title: title, subtitle: subtitle, symbol: item.symbol)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let kind = viewModel.report(at: indexPath.row).kind
        switch kind {
        case .pl:
            let vc = PLReportDetailViewController(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        case .abc:
            let vc = ABCReportDetailViewController(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        case .trends:
            let vc = TrendsReportDetailViewController(viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
