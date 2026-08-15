import TinyConstraints
import UIKit

final class PLReportDetailViewController: UIViewController, Loggable {

    private let sharedViewModel: ReportsHubViewModelType

    private let segmentedControl: UISegmentedControl = {
        let items = [
            NSLocalizedString("commonDay", tableName: "Global", value: "Day", comment: ""),
            NSLocalizedString("commonWeek", tableName: "Global", value: "Week", comment: ""),
            NSLocalizedString("commonMonth", tableName: "Global", value: "Month", comment: ""),
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
        title = NSLocalizedString("reportsPLTitle", tableName: "Global", comment: "")
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
            emptyStateLabel.text = NSLocalizedString(
                "commonLoading", tableName: "Global", value: "...", comment: "")
            let report = await sharedViewModel.buildPLReport()
            render(report: report)
        }
    }

    private func render(report: PLReport) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        kpiRows.removeAll()
        summaryRows.removeAll()
        countsRows.removeAll()

        let currency = NSLocalizedString(
            "commonCurrencyUAH", tableName: "Global", value: "₴", comment: "")

        // Section 1: Main KPIs (Sales, Gross Profit, Net Profit)
        addSectionHeader(
            title: NSLocalizedString(
                "kpiGroupSummary", tableName: "Global", value: "Summary", comment: ""))
        let kpiSales = makeKPI(
            title: NSLocalizedString("kpiSales", tableName: "Global", value: "Sales", comment: ""),
            value: report.sales, currency: currency, accent: Theme.current.tabBarTint)
        let kpiGross = makeKPI(
            title: NSLocalizedString(
                "kpiGrossProfit", tableName: "Global", value: "Gross Profit", comment: ""),
            value: report.grossProfit, currency: currency, accent: .systemGreen)
        let kpiNet = makeKPI(
            title: NSLocalizedString(
                "kpiNetProfit", tableName: "Global", value: "Net Profit", comment: ""),
            value: report.netProfit, currency: currency,
            accent: report.netProfit >= 0 ? .systemGreen : .systemRed)
        addRow(lhs: kpiSales, rhs: kpiGross)
        addSingleRow(kpiNet)

        // Section 2: Breakdown (COGS, Opex, Margin%)
        addSectionHeader(
            title: NSLocalizedString(
                "kpiGroupBreakdown", tableName: "Global", value: "Breakdown", comment: ""))
        let kpiCogs = makeKPI(
            title: NSLocalizedString("kpiCOGS", tableName: "Global", value: "COGS", comment: ""),
            value: report.cogs, currency: currency, accent: .systemOrange)
        let kpiOpex = makeKPI(
            title: NSLocalizedString(
                "kpiOpex", tableName: "Global", value: "Operating Expenses", comment: ""),
            value: report.opex, currency: currency, accent: .systemOrange)
        let kpiMargin = makeKPI(
            title: NSLocalizedString(
                "kpiMargin", tableName: "Global", value: "Gross Margin", comment: ""),
            value: report.grossMarginPercent, suffix: " %", accent: Theme.current.tabBarTint)
        addRow(lhs: kpiCogs, rhs: kpiOpex)
        addSingleRow(kpiMargin)

        // Section 3: Payment + Counts
        addSectionHeader(
            title: NSLocalizedString(
                "kpiGroupDetails", tableName: "Global", value: "Details", comment: ""))
        let kpiCash = makeKPI(
            title: NSLocalizedString("kpiCash", tableName: "Global", value: "Cash", comment: ""),
            value: report.cashSales, currency: currency, accent: Theme.current.primaryText)
        let kpiCard = makeKPI(
            title: NSLocalizedString("kpiCard", tableName: "Global", value: "Card", comment: ""),
            value: report.cardSales, currency: currency, accent: Theme.current.primaryText)
        let kpiOrders = makeKPI(
            title: NSLocalizedString(
                "kpiOrdersCount", tableName: "Global", value: "Orders", comment: ""),
            value: Double(report.ordersCount), suffix: nil, accent: Theme.current.secondaryText)
        let kpiExp = makeKPI(
            title: NSLocalizedString(
                "kpiExpensesCount", tableName: "Global", value: "Expenses", comment: ""),
            value: Double(report.expensesCount), suffix: nil, accent: Theme.current.secondaryText)
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
        f.currencySymbol = NSLocalizedString(
            "commonCurrencyUAH", tableName: "Global", value: "₴", comment: "")
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
        v.backgroundColor = Theme.current.secondaryBackground
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
