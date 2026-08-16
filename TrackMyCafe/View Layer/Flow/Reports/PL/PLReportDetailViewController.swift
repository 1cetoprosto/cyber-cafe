import TinyConstraints
import UIKit

final class PLReportDetailViewController: UIViewController, Loggable {

    private let sharedViewModel: ReportsHubViewModelType

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

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = UIConstants.mediumSpacing
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = UIEdgeInsets(
            top: UIConstants.standardPadding,
            left: UIConstants.standardPadding,
            bottom: UIConstants.standardPadding,
            right: UIConstants.standardPadding)
        return sv
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body
        label.textColor = Theme.current.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private var kpiRows: [PLKPIView] = []
    private var summaryRows: [PLKPIView] = []
    private var countsRows: [PLKPIView] = []

    init(viewModel: ReportsHubViewModelType) {
        self.sharedViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.current.primaryBackground
        title = R.string.global.reportsPLTitle()
        navigationController?.navigationBar.prefersLargeTitles = false

        setupLayout()
        bindViewModel()
        apply(sharedViewModel.currentPeriod, animated: false)

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func setupLayout() {
        let header = UIView()
        header.addSubview(segmentedControl)
        segmentedControl.edgesToSuperview(
            insets: UIEdgeInsets(
                top: UIConstants.mediumSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.mediumSpacing,
                right: UIConstants.standardPadding)
        )
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 64)
        navigationItem.titleView = header
        navigationItem.titleView?.widthAnchor.constraint(equalToConstant: view.bounds.width - 32)
            .isActive = true

        view.addSubview(scrollView)
        scrollView.edgesToSuperview(usingSafeArea: true)

        scrollView.addSubview(stackView)
        stackView.width(to: scrollView, offset: 0)
        stackView.edgesToSuperview()

        stackView.addArrangedSubview(emptyStateLabel)
    }

    private func bindViewModel() {
        sharedViewModel.onPeriodChanged = { [weak self] in
            guard let self = self else { return }
            self.apply(self.sharedViewModel.currentPeriod, animated: true)
            self.reloadData()
        }
    }

    private func apply(_ period: DashboardPeriod, animated: Bool) {
        segmentedControl.selectedSegmentIndex = sharedViewModel.segmentIndex(for: period)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        sharedViewModel.selectPeriod(at: sender.selectedSegmentIndex)
    }

    private func reloadData() {
        Task { @MainActor in
            emptyStateLabel.text = R.string.global.commonLoading()
            let report = await sharedViewModel.buildPLReport()
            render(report: report)
        }
    }

    private func render(report: PLReport) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        kpiRows.removeAll()
        summaryRows.removeAll()
        countsRows.removeAll()

        let currency = R.string.global.commonCurrencyUAH()

        // Section 1: Main KPIs (Sales, Gross Profit, Net Profit)
        addSectionHeader(title: R.string.global.kpiGroupSummary())
        let kpiSales = makeKPI(
            title: R.string.global.kpiSales(),
            value: report.sales, currency: currency, accent: Theme.current.primaryText)
        let kpiGross = makeKPI(
            title: R.string.global.kpiGrossProfit(),
            value: report.grossProfit, currency: currency,
            accent: report.grossProfit >= 0 ? .systemGreen : .systemRed)
        let kpiNet = makeKPI(
            title: R.string.global.kpiNetProfit(),
            value: report.netProfit, currency: currency,
            accent: report.netProfit >= 0 ? .systemGreen : .systemRed)
        addRow(lhs: kpiSales, rhs: kpiGross)
        addSingleRow(kpiNet)

        // Section 2: Breakdown (COGS, Opex, Margin%)
        addSectionHeader(title: R.string.global.kpiGroupBreakdown())
        let kpiCogs = makeKPI(
            title: R.string.global.kpiCOGS(),
            value: report.cogs, currency: currency, accent: Theme.current.primaryText)
        let kpiOpex = makeKPI(
            title: R.string.global.kpiOpex(),
            value: report.opex, currency: currency, accent: Theme.current.primaryText)
        let kpiMargin = makeKPI(
            title: R.string.global.kpiMargin(),
            value: report.grossMarginPercent, suffix: " %", accent: Theme.current.primaryText)
        addRow(lhs: kpiCogs, rhs: kpiOpex)
        addSingleRow(kpiMargin)

        // Section 3: Payment + Counts
        addSectionHeader(title: R.string.global.kpiGroupDetails())
        let kpiCash = makeKPI(
            title: R.string.global.kpiCash(),
            value: report.cashSales, currency: currency, accent: Theme.current.primaryText)
        let kpiCard = makeKPI(
            title: R.string.global.kpiCard(),
            value: report.cardSales, currency: currency, accent: Theme.current.primaryText)
        let kpiOrders = makeKPI(
            title: R.string.global.kpiOrdersCount(),
            value: Double(report.ordersCount), suffix: nil, accent: Theme.current.primaryText)
        let kpiExp = makeKPI(
            title: R.string.global.kpiExpensesCount(),
            value: Double(report.expensesCount), suffix: nil, accent: Theme.current.primaryText)
        addRow(lhs: kpiCash, rhs: kpiCard)
        addRow(lhs: kpiOrders, rhs: kpiExp)
    }

    private func addSectionHeader(title: String) {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = Typography.footnote
        label.textColor = Theme.current.secondaryText
        stackView.addArrangedSubview(label)
    }

    private func addRow(lhs: PLKPIView, rhs: PLKPIView) {
        let row = UIStackView(arrangedSubviews: [lhs, rhs])
        row.axis = .horizontal
        row.spacing = UIConstants.mediumSpacing
        row.distribution = .fillEqually
        stackView.addArrangedSubview(row)
    }

    private func addSingleRow(_ view: PLKPIView) {
        stackView.addArrangedSubview(view)
    }

    private func makeKPI(
        title: String, value: Double, currency: String? = nil, suffix: String? = nil,
        accent: UIColor
    ) -> PLKPIView {
        let kpi = PLKPIView()
        let text: String
        if let currency {
            let f = Self.amountFormatter
            f.currencySymbol = currency
            text = f.string(for: value) ?? ""
        } else if let suffix {
            text = (Self.percentFormatter.string(for: value) ?? "") + suffix
        } else {
            text = Self.integerFormatter.string(for: value) ?? ""
        }
        kpi.configure(title: title, value: text, accent: accent)
        kpiRows.append(kpi)
        return kpi
    }

    private static let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = R.string.global.commonCurrencyUAH()
        f.maximumFractionDigits = 0
        return f
    }()

    private static let percentFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f
    }()

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}

// MARK: - PL KPI View (single tile)

final class PLKPIView: UIView {
    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.cellBackground
        v.layer.cornerRadius = UIConstants.mediumCornerRadius
        return v
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.body
        l.textColor = Theme.current.secondaryText
        l.numberOfLines = 2
        l.adjustsFontForContentSizeCategory = true
        return l
    }()
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.title2DemiBold
        l.textColor = Theme.current.primaryText
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.allowsDefaultTighteningForTruncation = true
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(container)
        container.edgesToSuperview()
        container.height(min: 92)

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        titleLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        titleLabel.leftToSuperview(offset: UIConstants.mediumSpacing)
        titleLabel.rightToSuperview(offset: -UIConstants.mediumSpacing)

        valueLabel.topToBottom(
            of: titleLabel, offset: UIConstants.smallSpacing, relation: .equalOrGreater)
        valueLabel.left(to: titleLabel)
        valueLabel.right(to: titleLabel)
        valueLabel.bottomToSuperview(offset: -UIConstants.mediumSpacing, relation: .equalOrLess)
        valueLabel.centerYToSuperview(offset: 8, priority: .defaultHigh)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func configure(title: String, value: String, accent: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        valueLabel.textColor = accent
    }
}
