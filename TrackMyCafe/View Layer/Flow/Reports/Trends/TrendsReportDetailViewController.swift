import TinyConstraints
import UIKit

final class TrendPointCell: UITableViewCell {

    static let identifier = "TrendPointCell"

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.secondaryBackground
        v.layer.cornerRadius = UIConstants.mediumCornerRadius
        return v
    }()

    private let periodLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.bodyBold
        l.textColor = Theme.current.primaryText
        l.numberOfLines = 2
        return l
    }()

    private let salesLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.body
        l.textColor = Theme.current.primaryText
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let netLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.title3DemiBold
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let deltaLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnote
        l.textAlignment = .right
        return l
    }()

    private let breakdownStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = UIConstants.standardSpacing
        sv.distribution = .fillEqually
        return sv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.edgesToSuperview(
            insets: UIEdgeInsets(
                top: UIConstants.smallSpacing,
                left: UIConstants.standardPadding,
                bottom: UIConstants.smallSpacing,
                right: UIConstants.standardPadding)
        )

        containerView.addSubview(periodLabel)
        containerView.addSubview(netLabel)
        containerView.addSubview(deltaLabel)
        containerView.addSubview(salesLabel)
        containerView.addSubview(breakdownStack)

        periodLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        periodLabel.leftToSuperview(offset: UIConstants.mediumSpacing)
        periodLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        netLabel.top(to: periodLabel)
        netLabel.rightToSuperview(offset: -UIConstants.mediumSpacing)
        netLabel.leftToRight(of: periodLabel, offset: UIConstants.smallSpacing, relation: .equalOrGreater)

        deltaLabel.topToBottom(of: netLabel, offset: 2)
        deltaLabel.right(to: netLabel)

        salesLabel.topToBottom(of: periodLabel, offset: UIConstants.smallSpacing)
        salesLabel.left(to: periodLabel)

        breakdownStack.axis = .vertical
        breakdownStack.spacing = 2
        breakdownStack.topToBottom(of: salesLabel, offset: 4)
        breakdownStack.left(to: periodLabel)
        breakdownStack.right(to: netLabel)
        breakdownStack.bottomToSuperview(offset: -UIConstants.mediumSpacing)
    }

    func configure(point: TrendPoint, previousSales: Double?, previousNet: Double?, currency: String) {
        periodLabel.text = point.label

        let fCurrency = TrendPointCell.currencyFormatter(currency: currency)
        let deltaPct = Self.deltaPercent(current: point.netProfit, previous: previousNet)

        netLabel.text = fCurrency.string(for: point.netProfit) ?? ""
        netLabel.textColor = point.netProfit >= 0 ? .systemGreen : .systemRed

        let deltaText: String
        if let previousNet, previousNet != 0 {
            let sign = deltaPct >= 0 ? "+" : ""
            deltaText = String(format: "%@%.1f%% vs prev", sign, deltaPct)
        } else {
            deltaText = ""
        }
        deltaLabel.text = deltaText
        deltaLabel.textColor = deltaPct >= 0 ? .systemGreen : .systemRed

        salesLabel.text = "Sales: " + (fCurrency.string(for: point.sales) ?? "")

        breakdownStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addBreakdownRow(title: "COGS", value: point.cogs, currency: currency, color: .systemOrange)
        addBreakdownRow(title: "Opex", value: point.opex, currency: currency, color: .systemOrange)
    }

    private func addBreakdownRow(title: String, value: Double, currency: String, color: UIColor) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing

        let t = UILabel()
        t.font = Typography.footnoteLight
        t.textColor = Theme.current.secondaryText
        t.text = title

        let v = UILabel()
        v.font = Typography.footnote
        v.textColor = color
        v.textAlignment = .right
        v.text = TrendPointCell.currencyFormatter(currency: currency).string(for: value) ?? ""

        stack.addArrangedSubview(t)
        stack.addArrangedSubview(v)
        breakdownStack.addArrangedSubview(stack)
    }

    private static func deltaPercent(current: Double, previous: Double?) -> Double {
        guard let previous, previous != 0 else { return 0 }
        return ((current - previous) / abs(previous)) * 100
    }

    private static func currencyFormatter(currency: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = currency
        f.maximumFractionDigits = 0
        return f
    }
}

final class TrendsReportDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, Loggable {

    private let sharedViewModel: ReportsHubViewModelType

    private let segmentedControl: UISegmentedControl = {
        let items = [R.string.global.day(), R.string.global.week(), R.string.global.month()]
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

    private let summaryStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = UIConstants.mediumSpacing
        return sv
    }()

    private let tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TrendPointCell.self, forCellReuseIdentifier: TrendPointCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        return tableView
    }()

    private let emptyStateLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.body
        l.textColor = Theme.current.secondaryText
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private var points: [TrendPoint] = []

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
        title = NSLocalizedString("reportsTrendsTitle", tableName: "Global", value: "Trends", comment: "")
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView.delegate = self
        tableView.dataSource = self

        setupLayout()
        bindViewModel()
        apply(sharedViewModel.currentPeriod)

        segmentedControl.addTarget(self, action: #selector(periodSegmentChanged), for: .valueChanged)
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
        navigationItem.titleView?.widthAnchor.constraint(equalToConstant: view.bounds.width - 32).isActive = true

        let tableHeader = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 100))
        let wrapper = UIStackView(arrangedSubviews: [summaryStack])
        wrapper.axis = .vertical
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.layoutMargins = UIEdgeInsets(
            top: UIConstants.mediumSpacing,
            left: UIConstants.standardPadding,
            bottom: UIConstants.mediumSpacing,
            right: UIConstants.standardPadding)
        tableHeader.addSubview(wrapper)
        wrapper.edgesToSuperview()
        tableView.tableHeaderView = tableHeader

        view.addSubview(tableView)
        tableView.edgesToSuperview(usingSafeArea: true)
    }

    private func bindViewModel() {
        sharedViewModel.onPeriodChanged = { [weak self] in
            guard let self = self else { return }
            self.apply(self.sharedViewModel.currentPeriod)
            self.reloadData()
        }
    }

    private func apply(_ period: DashboardPeriod) {
        segmentedControl.selectedSegmentIndex = sharedViewModel.segmentIndex(for: period)
    }

    @objc private func periodSegmentChanged(_ sender: UISegmentedControl) {
        sharedViewModel.selectPeriod(at: sender.selectedSegmentIndex)
    }

    private func reloadData() {
        Task { @MainActor in
            emptyStateLabel.text = NSLocalizedString("commonLoading", tableName: "Global", value: "...", comment: "")
            let report = await sharedViewModel.buildTrendsReport(periodsBack: 6)
            render(report: report)
        }
    }

    private func render(report: TrendsReport) {
        points = report.points

        summaryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let currency = NSLocalizedString("commonCurrencyUAH", tableName: "Global", value: "₴", comment: "")

        let totalSales = points.reduce(0) { $0 + $1.sales }
        let totalNet = points.reduce(0) { $0 + $1.netProfit }
        let avgNet = points.isEmpty ? 0 : totalNet / Double(points.count)

        addSummaryCard(title: "Total Sales", value: totalSales, currency: currency, color: Theme.current.tabBarTint)
        addSummaryCard(title: "Total Net", value: totalNet, currency: currency, color: totalNet >= 0 ? .systemGreen : .systemRed)
        addSummaryCard(title: "Avg Net / Period", value: avgNet, currency: currency, color: avgNet >= 0 ? .systemGreen : .systemRed)

        if points.isEmpty {
            emptyStateLabel.text = NSLocalizedString("trendsEmpty", tableName: "Global", value: "No data for selected periodicity.", comment: "")
            tableView.backgroundView = emptyStateLabel
        } else {
            tableView.backgroundView = nil
        }
        tableView.reloadData()
    }

    private func addSummaryCard(title: String, value: Double, currency: String, color: UIColor) {
        let card = UIView()
        card.backgroundColor = Theme.current.secondaryBackground
        card.layer.cornerRadius = UIConstants.mediumCornerRadius

        let titleL = UILabel()
        titleL.font = Typography.footnote
        titleL.textColor = Theme.current.secondaryText
        titleL.text = title
        titleL.numberOfLines = 2

        let valueL = UILabel()
        valueL.font = Typography.title3DemiBold
        valueL.textColor = color
        valueL.adjustsFontSizeToFitWidth = true
        valueL.minimumScaleFactor = 0.7

        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = currency
        f.maximumFractionDigits = 0
        valueL.text = f.string(for: value)

        card.addSubview(titleL)
        card.addSubview(valueL)
        titleL.topToSuperview(offset: UIConstants.smallSpacing)
        titleL.leftToSuperview(offset: UIConstants.smallSpacing)
        titleL.rightToSuperview(offset: -UIConstants.smallSpacing)

        valueL.topToBottom(of: titleL, offset: 4, relation: .equalOrGreater)
        valueL.left(to: titleL)
        valueL.right(to: titleL)
        valueL.bottomToSuperview(offset: -UIConstants.smallSpacing, relation: .equalOrLess)
        valueL.centerYToSuperview(offset: 10, relation: .equalOrLess, priority: .defaultHigh)

        summaryStack.addArrangedSubview(card)
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        points.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TrendPointCell.identifier, for: indexPath) as! TrendPointCell
        let point = points[indexPath.row]
        let previous = indexPath.row > 0 ? points[indexPath.row - 1] : nil
        let currency = NSLocalizedString("commonCurrencyUAH", tableName: "Global", value: "₴", comment: "")
        cell.configure(point: point, previousSales: previous?.sales, previousNet: previous?.netProfit, currency: currency)
        return cell
    }
}
