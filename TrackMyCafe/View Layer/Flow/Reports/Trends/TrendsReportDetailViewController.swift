import TinyConstraints
import UIKit

final class TrendPointCell: UITableViewCell {

    static let identifier = "TrendPointCell"

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.cellBackground
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
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.numberOfLines = 1
        return l
    }()

    private let netLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.title2DemiBold
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.numberOfLines = 1
        return l
    }()

    private let deltaLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnote
        l.textAlignment = .right
        l.numberOfLines = 1
        return l
    }()

    private let breakdownStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 2
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
        netLabel.leftToRight(
            of: periodLabel, offset: UIConstants.smallSpacing, relation: .equalOrGreater)

        deltaLabel.topToBottom(of: netLabel, offset: 2)
        deltaLabel.right(to: netLabel)

        salesLabel.topToBottom(of: periodLabel, offset: UIConstants.smallSpacing)
        salesLabel.left(to: periodLabel)
        salesLabel.right(to: netLabel)

        breakdownStack.topToBottom(of: salesLabel, offset: 4)
        breakdownStack.left(to: periodLabel)
        breakdownStack.right(to: netLabel)
        breakdownStack.bottomToSuperview(offset: -UIConstants.mediumSpacing)
    }

    func configure(
        point: TrendPoint, previousSales: Double?, previousNet: Double?, currency: String,
        costsShown: Bool
    ) {
        periodLabel.text = point.label

        let fCurrency = TrendPointCell.currencyFormatter(currency: currency)
        let deltaPct = Self.deltaPercent(current: point.netProfit, previous: previousNet)

        netLabel.text = fCurrency.string(for: point.netProfit) ?? ""
        netLabel.textColor = point.netProfit >= 0 ? .systemGreen : .systemRed

        let deltaText: String
        if let previousNet, previousNet != 0 {
            let sign = deltaPct >= 0 ? "+" : ""
            deltaText =
                deltaPct >= 0
                ? R.string.global.trendsBetterByFormat(sign, deltaPct)
                : R.string.global.trendsWorseByFormat(sign, deltaPct)
        } else {
            deltaText = ""
        }
        deltaLabel.text = deltaText
        deltaLabel.textColor = deltaPct >= 0 ? .systemGreen : .systemRed

        salesLabel.text = R.string.global.trendsSalesPrefixFormat(
            fCurrency.string(for: point.sales) ?? "")

        // Simple costs show/hide: populate but toggle isHidden (bottom constraint pins to container, so height ok if all hidden inside empty stack)
        breakdownStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if costsShown {
            addBreakdownRow(
                title: R.string.global.trendsCOGS(),
                value: point.cogs, currency: currency, color: Theme.current.primaryText)
            addBreakdownRow(
                title: R.string.global.trendsOpex(),
                value: point.opex, currency: currency, color: Theme.current.primaryText)
        }
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

final class TrendsReportDetailViewController: UIViewController, UITableViewDelegate,
    UITableViewDataSource, Loggable
{

    private let sharedViewModel: ReportsHubViewModelType

    private let segmentedControl: DefaultSegmentedControl = {
        let items = [
            R.string.global.commonDay(),
            R.string.global.commonWeek(),
            R.string.global.commonMonth(),
        ]
        let control = DefaultSegmentedControl(items: items)
        return control
    }()

    private let costsToggleButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(R.string.global.commonShowCosts(), for: .normal)
        b.titleLabel?.font = Typography.bodyBold
        b.setTitleColor(Theme.current.tabBarTint, for: .normal)
        b.contentHorizontalAlignment = .leading
        return b
    }()

    private var costsShown: Bool = false

    private let tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TrendPointCell.self, forCellReuseIdentifier: TrendPointCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 130
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
        title = R.string.global.reportsTrendsTitle()
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView.delegate = self
        tableView.dataSource = self

        setupLayout()
        bindViewModel()
        apply(sharedViewModel.currentPeriod)

        segmentedControl.addTarget(
            self, action: #selector(periodSegmentChanged), for: .valueChanged)
        costsToggleButton.addTarget(
            self, action: #selector(toggleCosts), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func setupLayout() {
        navigationItem.titleView = nil

        // BIG summary header: one total NET for all periods
        let tableHeader = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 286))
        tableHeader.tag = 999
        tableView.tableHeaderView = tableHeader

        view.addSubview(tableView)
        tableView.edgesToSuperview(usingSafeArea: true)
    }

    private func renderSummaryHeader(
        totalNet: Double, totalSales: Double, totalCosts: Double, currency: String
    ) {
        guard let header = tableView.tableHeaderView, header.tag == 999 else { return }
        header.subviews.forEach { $0.removeFromSuperview() }

        segmentedControl.removeFromSuperview()
        header.addSubview(segmentedControl)
        segmentedControl.topToSuperview(offset: UIConstants.standardSpacing)
        segmentedControl.leftToSuperview(offset: UIConstants.standardPadding)
        segmentedControl.rightToSuperview(offset: -UIConstants.standardPadding)
        let netCard = UIView()
        netCard.backgroundColor = Theme.current.cellBackground
        netCard.layer.cornerRadius = UIConstants.mediumCornerRadius

        let netTitleL = UILabel()
        netTitleL.font = Typography.footnote
        netTitleL.textColor = Theme.current.secondaryText
        netTitleL.numberOfLines = 2
        netTitleL.text = R.string.global.trendsBigNetRemainedPeriod()

        let netValueL = UILabel()
        netValueL.font = Typography.largeTitleBold
        netValueL.textColor = totalNet >= 0 ? .systemGreen : .systemRed
        netValueL.adjustsFontSizeToFitWidth = true
        netValueL.minimumScaleFactor = 0.6
        netValueL.numberOfLines = 1

        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = currency
        f.maximumFractionDigits = 0
        netValueL.text = f.string(for: totalNet)

        netCard.addSubview(netTitleL)
        netCard.addSubview(netValueL)

        netTitleL.topToSuperview(offset: UIConstants.smallSpacing)
        netTitleL.leftToSuperview(offset: UIConstants.mediumSpacing)
        netTitleL.rightToSuperview(offset: -UIConstants.mediumSpacing)

        netValueL.topToBottom(of: netTitleL, offset: 4, relation: .equalOrGreater)
        netValueL.left(to: netTitleL)
        netValueL.right(to: netTitleL)
        netValueL.height(min: 56)

        // Footer: Sales | Costs small row
        let smallSV = UIStackView()
        smallSV.axis = .horizontal
        smallSV.distribution = .fillEqually
        smallSV.spacing = UIConstants.mediumSpacing

        smallSV.addArrangedSubview(
            makeSmallSummary(
                title: R.string.global.hubBigSalesLabel(),
                valueStr: f.string(for: totalSales) ?? "0", color: Theme.current.primaryText))
        smallSV.addArrangedSubview(
            makeSmallSummary(
                title: R.string.global.hubBigCostsLabel(),
                valueStr: f.string(for: totalCosts) ?? "0", color: .systemOrange))

        netCard.addSubview(smallSV)
        smallSV.topToBottom(of: netValueL, offset: UIConstants.smallSpacing)
        smallSV.left(to: netTitleL)
        smallSV.right(to: netTitleL)
        smallSV.bottomToSuperview(offset: -UIConstants.smallSpacing)

        // Wrap: netCard + costsToggleButton
        let wrapper = UIStackView(arrangedSubviews: [netCard, costsToggleButton])
        wrapper.axis = .vertical
        wrapper.spacing = UIConstants.smallSpacing
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.layoutMargins = UIEdgeInsets(
            top: UIConstants.mediumSpacing,
            left: UIConstants.standardPadding,
            bottom: UIConstants.mediumSpacing,
            right: UIConstants.standardPadding)

        header.addSubview(wrapper)
        wrapper.topToBottom(of: segmentedControl, offset: UIConstants.smallSpacing)
        wrapper.leftToSuperview()
        wrapper.rightToSuperview()
        wrapper.bottomToSuperview()
    }

    private func makeSmallSummary(title: String, valueStr: String, color: UIColor) -> UIView {
        let titleL = UILabel()
        titleL.font = Typography.footnoteLight
        titleL.textColor = Theme.current.secondaryText
        titleL.text = title

        let valueL = UILabel()
        valueL.font = Typography.calloutDemi
        valueL.textColor = color
        valueL.adjustsFontSizeToFitWidth = true
        valueL.minimumScaleFactor = 0.7
        valueL.text = valueStr

        let sv = UIStackView(arrangedSubviews: [titleL, valueL])
        sv.axis = .vertical
        sv.spacing = 2
        return sv
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

    @objc private func toggleCosts() {
        costsShown.toggle()
        let title =
            costsShown
            ? R.string.global.commonHideCosts() : R.string.global.commonShowCosts()
        costsToggleButton.setTitle(title, for: .normal)
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        tableView.reloadData()
    }

    private func reloadData() {
        Task { @MainActor in
            emptyStateLabel.text = R.string.global.commonLoading()
            let report = await sharedViewModel.buildTrendsReport(periodsBack: 6)
            render(report: report)
        }
    }

    private func render(report: TrendsReport) {
        points = report.points

        let currency = R.string.global.commonCurrencyUAH()
        let totalSales = points.reduce(0) { $0 + $1.sales }
        let totalNet = points.reduce(0) { $0 + $1.netProfit }
        let totalCosts = points.reduce(0) { $0 + $1.cogs + $1.opex }

        renderSummaryHeader(
            totalNet: totalNet, totalSales: totalSales, totalCosts: totalCosts,
            currency: currency)

        if points.isEmpty {
            emptyStateLabel.text = R.string.global.trendsEmpty()
            tableView.backgroundView = emptyStateLabel
        } else {
            tableView.backgroundView = nil
        }
        tableView.reloadData()
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        points.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: TrendPointCell.identifier, for: indexPath)
            as! TrendPointCell
        let point = points[indexPath.row]
        let previous = indexPath.row > 0 ? points[indexPath.row - 1] : nil
        let currency = R.string.global.commonCurrencyUAH()
        cell.configure(
            point: point, previousSales: previous?.sales, previousNet: previous?.netProfit,
            currency: currency, costsShown: costsShown)
        return cell
    }
}
