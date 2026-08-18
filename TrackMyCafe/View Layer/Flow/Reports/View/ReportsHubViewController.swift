import TinyConstraints
import UIKit

final class ReportsHubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    Loggable
{

    private let viewModel: ReportsHubViewModelType

    private let segmentedControl: DefaultSegmentedControl = {
        let items = [
            R.string.global.commonDay(),
            R.string.global.commonWeek(),
            R.string.global.commonMonth(),
        ]
        let control = DefaultSegmentedControl(items: items)
        return control
    }()

    private let periodInfoLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body
        label.textColor = Theme.current.secondaryText
        label.textAlignment = .center
        return label
    }()

    // MARK: - Hero KPI Card (at-a-glance truth, unified Home TodayCardView style: badge + icon + title + value)

    private let heroCardView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.cellBackground
        v.layer.cornerRadius = UIConstants.extraLargeCornerRadius
        return v
    }()

    private let heroNetIconBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = UIConstants.badgeCornerRadius
        return v
    }()
    private let heroNetIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
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

    private let heroSalesBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        v.layer.cornerRadius = 14
        return v
    }()
    private let heroSalesIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "arrow.up.right")
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
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

    private let heroCostsBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        v.layer.cornerRadius = 14
        return v
    }()
    private let heroCostsIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "arrow.down.right")
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
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
        // Hero card layout (unified badge-icon + title + value pattern, same as Home)
        heroNetIconBadge.addSubview(heroNetIconView)
        heroNetIconView.size(
            CGSize(width: UIConstants.largeIconSize, height: UIConstants.largeIconSize))
        heroNetIconView.centerInSuperview()
        let badgeSize = UIConstants.badgeSize
        heroNetIconBadge.size(CGSize(width: badgeSize, height: badgeSize))

        heroCardView.addSubview(heroNetIconBadge)
        heroCardView.addSubview(heroNetTitleLabel)
        heroCardView.addSubview(heroNetValueLabel)

        // Net header row: badge + title
        heroNetIconBadge.leftToSuperview(offset: UIConstants.standardPadding)
        heroNetIconBadge.topToSuperview(offset: UIConstants.standardPadding)
        heroNetTitleLabel.leftToRight(of: heroNetIconBadge, offset: UIConstants.smallSpacing)
        heroNetTitleLabel.top(to: heroNetIconBadge, offset: 0)
        heroNetTitleLabel.rightToSuperview(offset: -UIConstants.standardPadding)

        heroNetValueLabel.topToBottom(of: heroNetTitleLabel, offset: 4)
        heroNetValueLabel.left(to: heroNetTitleLabel)
        heroNetValueLabel.right(to: heroNetTitleLabel)

        // Sales mini row with icon badge
        heroSalesBadge.addSubview(heroSalesIcon)
        heroSalesIcon.size(CGSize(width: 16, height: 16))
        heroSalesIcon.centerInSuperview()
        heroSalesBadge.size(CGSize(width: 28, height: 28))
        let salesTitleSV = UIStackView(arrangedSubviews: [heroSalesTitleLabel, heroSalesValueLabel])
        salesTitleSV.axis = .vertical
        salesTitleSV.spacing = 2
        let salesSV = UIStackView(arrangedSubviews: [heroSalesBadge, salesTitleSV])
        salesSV.axis = .horizontal
        salesSV.spacing = UIConstants.smallSpacing
        salesSV.alignment = .center

        // Costs mini row with icon badge
        heroCostsBadge.addSubview(heroCostsIcon)
        heroCostsIcon.size(CGSize(width: 16, height: 16))
        heroCostsIcon.centerInSuperview()
        heroCostsBadge.size(CGSize(width: 28, height: 28))
        let costsTitleSV = UIStackView(arrangedSubviews: [heroCostsTitleLabel, heroCostsValueLabel])
        costsTitleSV.axis = .vertical
        costsTitleSV.spacing = 2
        let costsSV = UIStackView(arrangedSubviews: [heroCostsBadge, costsTitleSV])
        costsSV.axis = .horizontal
        costsSV.spacing = UIConstants.smallSpacing
        costsSV.alignment = .center

        let bottomSV = UIStackView(arrangedSubviews: [salesSV, costsSV])
        bottomSV.axis = .horizontal
        bottomSV.distribution = .fillEqually
        bottomSV.spacing = UIConstants.standardPadding

        heroCardView.addSubview(bottomSV)
        bottomSV.topToBottom(of: heroNetValueLabel, offset: UIConstants.standardSpacing)
        bottomSV.leftToSuperview(offset: UIConstants.standardPadding)
        bottomSV.rightToSuperview(offset: -UIConstants.standardPadding)
        bottomSV.bottomToSuperview(offset: -UIConstants.standardPadding)

        // Header: segmented + period + hero card
        segmentedControl.height(40)
        let headerStack = UIStackView(arrangedSubviews: [
            segmentedControl,
            periodInfoLabel,
            heroCardView,
        ])
        headerStack.axis = .vertical
        headerStack.spacing = UIConstants.standardSpacing
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(
            top: UIConstants.standardSpacing,
            left: UIConstants.standardPadding,
            bottom: UIConstants.mediumSpacing,
            right: UIConstants.standardPadding
        )

        headerStack.frame = CGRect(
            x: 0, y: 0,
            width: view.bounds.width,
            height: 310
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
        let idx = viewModel.segmentIndex(for: period)
        segmentedControl.selectedSegmentIndex = idx
        periodInfoLabel.text = periodDescription(for: period)
        logger.info(
            "ReportsHub apply period=\(String(describing: period)) segIndex=\(idx) desc=\(periodInfoLabel.text ?? "")"
        )
        tableView.reloadData()
        view.layoutIfNeeded()
        loadHeroCard(for: period)
    }

    private func loadHeroCard(for period: DashboardPeriod) {
        // skeleton until real data
        let currency = R.string.global.commonCurrencyUAH()
        heroSalesValueLabel.text = Self.currencyString(value: 0, currency: currency)
        heroCostsValueLabel.text = Self.currencyString(value: 0, currency: currency)
        heroNetValueLabel.text = Self.currencyString(value: 0, currency: currency)
        heroNetValueLabel.textColor = Theme.current.primaryText
        heroNetIconView.image = UIImage(
            systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
        heroNetIconView.tintColor = Theme.current.secondaryText
        heroNetIconBadge.backgroundColor = Theme.current.secondaryText.withAlphaComponent(0.12)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            logger.info("ReportsHub loadHeroCard period=\(String(describing: period)) start")
            let report = await self.viewModel.buildPLReport()
            logger.info(
                "ReportsHub loadHeroCard period=\(String(describing: period))"
                    + " sales=\(report.sales) costs=\(report.cogs + report.opex) net=\(report.netProfit)"
            )
            self.applyHeroCard(
                sales: report.sales,
                totalCosts: report.cogs + report.opex,
                netProfit: report.netProfit,
                currency: currency
            )
            self.view.layoutIfNeeded()
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
        let isPositive = netProfit >= 0
        heroNetValueLabel.textColor = isPositive ? .systemGreen : .systemRed
        heroNetIconView.image = UIImage(
            systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
        heroNetIconView.tintColor = isPositive ? .systemGreen : .systemRed
        heroNetIconBadge.backgroundColor =
            (isPositive ? UIColor.systemGreen : UIColor.systemRed).withAlphaComponent(0.15)
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
        logger.info("ReportsHub segmentChanged → index \(sender.selectedSegmentIndex)")
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
