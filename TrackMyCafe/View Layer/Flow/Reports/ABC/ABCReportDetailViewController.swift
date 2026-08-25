import TinyConstraints
import UIKit

final class ABCProductCell: UITableViewCell {

    static let identifier = "ABCProductCell"

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.cellBackground
        v.layer.cornerRadius = UIConstants.mediumCornerRadius
        return v
    }()

    private let bucketBadge: UILabel = {
        let l = AppLabel(style: .title3DemiBold)
        l.apply(.title3DemiBold)
        l.textAlignment = .center
        l.textColor = .white
        l.layer.cornerRadius = 18
        l.layer.masksToBounds = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = AppLabel(style: .footnote)
        l.apply(.bodyBold)
        l.textColor = Theme.current.primaryText
        l.numberOfLines = 2
        return l
    }()

    private let qtyLabel: UILabel = {
        let l = AppLabel(style: .footnote)
        l.apply(.footnote)
        l.textColor = Theme.current.secondaryText
        return l
    }()

    private let salesLabel: UILabel = {
        let l = AppLabel(style: .footnote)
        l.apply(.bodyMedium)
        l.textColor = Theme.current.primaryText
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let shareLabel: UILabel = {
        let l = AppLabel(style: .footnote)
        l.apply(.footnote)
        l.textColor = Theme.current.secondaryText
        l.textAlignment = .right
        return l
    }()

    private let cumulativeLabel: UILabel = {
        let l = AppLabel(style: .footnote)
        l.apply(.footnoteLight)
        l.textColor = Theme.current.secondaryText
        l.textAlignment = .right
        return l
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

        containerView.addSubview(bucketBadge)
        containerView.addSubview(nameLabel)
        containerView.addSubview(qtyLabel)
        containerView.addSubview(salesLabel)
        containerView.addSubview(shareLabel)
        containerView.addSubview(cumulativeLabel)

        bucketBadge.leftToSuperview(offset: UIConstants.mediumSpacing)
        bucketBadge.centerYToSuperview()
        bucketBadge.size(CGSize(width: 36, height: 36))

        nameLabel.leftToRight(of: bucketBadge, offset: UIConstants.mediumSpacing)
        nameLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        nameLabel.rightToLeft(
            of: salesLabel, offset: -UIConstants.mediumSpacing,
            relation: .equalOrLess)
        nameLabel.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)
        salesLabel.setContentCompressionResistancePriority(
            .required, for: .horizontal)
        salesLabel.setContentHuggingPriority(.required, for: .horizontal)

        qtyLabel.left(to: nameLabel)
        qtyLabel.topToBottom(of: nameLabel, offset: UIConstants.smallSpacing)
        qtyLabel.bottomToSuperview(offset: -UIConstants.mediumSpacing, relation: .equalOrLess)

        salesLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        salesLabel.rightToSuperview(offset: -UIConstants.mediumSpacing)
        salesLabel.width(min: 60)

        shareLabel.topToBottom(of: salesLabel, offset: 2)
        shareLabel.right(to: salesLabel)

        cumulativeLabel.topToBottom(of: shareLabel, offset: 2)
        cumulativeLabel.right(to: salesLabel)
        cumulativeLabel.bottomToSuperview(
            offset: -UIConstants.mediumSpacing, relation: .equalOrLess)
    }

    func configure(row: ABCProductRow, currency: String) {
        nameLabel.text = row.productName

        let qtyStr = ABCProductCell.integerFormatter.string(for: row.quantity) ?? ""
        qtyLabel.text = R.string.global.abcQtyPrefixFormat(qtyStr)

        let salesStr =
            ABCProductCell.currencyFormatter(currency: currency).string(for: row.sales) ?? ""
        salesLabel.text = salesStr

        let sharePct = String(format: "%.1f%%", row.sharePercent)
        shareLabel.text = R.string.global.abcSharePrefixFormat(sharePct)
        let cumulativeStr = String(format: "%.1f%%", row.cumulativePercent)
        cumulativeLabel.text = R.string.global.abcCumulativePrefixFormat(cumulativeStr)

        let (title, color) = ABCProductCell.bucketMeta(row.bucket)
        bucketBadge.text = title
        bucketBadge.backgroundColor = color
    }

    private static func bucketMeta(_ bucket: ABCBucket) -> (String, UIColor) {
        switch bucket {
        case .a: return ("💰", .systemGreen)
        case .b: return ("⚖️", .systemOrange)
        case .c: return ("🤔", .systemGray)
        }
    }

    private static func currencyFormatter(currency: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = currency
        f.maximumFractionDigits = 0
        return f
    }

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}

final class ABCReportDetailViewController: UIViewController, UITableViewDelegate,
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

    private let rankingControl: DefaultSegmentedControl = {
        let items = [
            R.string.global.abcRankingSales(),
            R.string.global.abcRankingGross(),
        ]
        let control = DefaultSegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()

    private let rankingTitleLabel: UILabel = {
        let l = AppLabel(style: .headline)
        l.apply(.headline)
        l.textColor = Theme.current.primaryText
        l.text = R.string.global.abcRankingTitle()
        return l
    }()

    private let summaryStack = UIStackView()

    private static let showMoreIdentifier = "ABCShowMoreCell"

    private let tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ABCProductCell.self, forCellReuseIdentifier: ABCProductCell.identifier)
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: ABCReportDetailViewController.showMoreIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        tableView.separatorStyle = .none
        return tableView
    }()

    private let emptyStateLabel: UILabel = {
        let l = AppLabel(style: .bodyMultiline)
        l.apply(.body)
        l.textColor = Theme.current.secondaryText
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private var rows: [ABCProductRow] = []
    private var countsByBucket: [ABCBucket: Int] = [:]
    private var showAllBucketC: Bool = false

    private var visibleRows: [ABCProductRow] {
        guard !showAllBucketC else { return rows }
        let bucketCStartIdx = rows.firstIndex { $0.bucket == .c } ?? rows.endIndex
        let firstC = rows[bucketCStartIdx...]
        let limitedC = firstC.prefix(5)
        return Array(rows[..<bucketCStartIdx]) + Array(limitedC)
    }

    private var hiddenBucketCCount: Int {
        guard !showAllBucketC else { return 0 }
        let bucketCStartIdx = rows.firstIndex { $0.bucket == .c } ?? rows.endIndex
        let cTotal = rows[bucketCStartIdx...].count
        return max(0, cTotal - 5)
    }

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
        title = R.string.global.reportsABCTitle()
        navigationController?.navigationBar.prefersLargeTitles = false

        tableView.delegate = self
        tableView.dataSource = self

        setupLayout()
        bindViewModel()
        apply(sharedViewModel.currentPeriod)

        segmentedControl.addTarget(
            self, action: #selector(periodSegmentChanged), for: .valueChanged)
        rankingControl.addTarget(self, action: #selector(rankingSegmentChanged), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func setupLayout() {
        navigationItem.titleView = nil

        let tableHeader = UIView(
            frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 240))
        tableHeader.addSubview(segmentedControl)
        segmentedControl.topToSuperview(offset: UIConstants.smallSpacing)
        segmentedControl.leftToSuperview(offset: UIConstants.standardPadding)
        segmentedControl.rightToSuperview(offset: -UIConstants.standardPadding)

        // Ranking card container
        let rankingCard = UIView()
        rankingCard.backgroundColor = Theme.current.cellBackground
        rankingCard.layer.cornerRadius = UIConstants.mediumCornerRadius
        rankingCard.addSubview(rankingTitleLabel)
        rankingCard.addSubview(rankingControl)
        rankingTitleLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        rankingTitleLabel.leftToSuperview(offset: UIConstants.mediumSpacing)
        rankingTitleLabel.rightToSuperview(offset: -UIConstants.mediumSpacing)
        rankingControl.topToBottom(of: rankingTitleLabel, offset: UIConstants.smallSpacing)
        rankingControl.left(to: rankingTitleLabel)
        rankingControl.right(to: rankingTitleLabel)
        rankingControl.bottomToSuperview(offset: -UIConstants.mediumSpacing)
        rankingCard.height(min: 76)

        let vStack = UIStackView(arrangedSubviews: [rankingCard, summaryStack])
        vStack.axis = .vertical
        vStack.spacing = UIConstants.mediumSpacing
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.layoutMargins = UIEdgeInsets(
            top: 0,
            left: UIConstants.standardPadding,
            bottom: UIConstants.mediumSpacing,
            right: UIConstants.standardPadding)
        tableHeader.addSubview(vStack)
        vStack.topToBottom(of: segmentedControl, offset: UIConstants.standardSpacing)
        vStack.leftToSuperview()
        vStack.rightToSuperview()
        vStack.bottomToSuperview()
        tableView.tableHeaderView = tableHeader

        view.addSubview(tableView)
        tableView.edgesToSuperview(usingSafeArea: true)

        summaryStack.axis = .horizontal
        summaryStack.distribution = .fillEqually
        summaryStack.spacing = UIConstants.mediumSpacing
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

    @objc private func rankingSegmentChanged(_ sender: UISegmentedControl) {
        reloadData()
    }

    private var rankingKey: ABCRankingKey {
        rankingControl.selectedSegmentIndex == 0 ? .sales : .grossProfit
    }

    private func reloadData() {
        Task { @MainActor in
            emptyStateLabel.text = R.string.global.commonLoading()
            let report = await sharedViewModel.buildABCReport(rankingKey: rankingKey)
            render(report: report)
        }
    }

    private func render(report: ABCReport) {
        rows = report.rows
        countsByBucket = report.countsByBucket
        showAllBucketC = false

        summaryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let currency = R.string.global.commonCurrencyUAH()
        let bucketSales = Dictionary(grouping: rows, by: { $0.bucket })
            .mapValues { $0.reduce(0) { $0 + $1.sales } }
        addSummaryCard(
            title: R.string.global.abcBucketATitle(),
            count: countsByBucket[.a] ?? 0, value: bucketSales[.a] ?? 0,
            currency: currency, color: .systemGreen)
        addSummaryCard(
            title: R.string.global.abcBucketBTitle(),
            count: countsByBucket[.b] ?? 0, value: bucketSales[.b] ?? 0,
            currency: currency, color: .systemOrange)
        addSummaryCard(
            title: R.string.global.abcBucketCTitle(),
            count: countsByBucket[.c] ?? 0, value: bucketSales[.c] ?? 0,
            currency: currency, color: .systemGray)

        if rows.isEmpty {
            emptyStateLabel.text = R.string.global.abcEmpty()
            tableView.backgroundView = emptyStateLabel
        } else {
            tableView.backgroundView = nil
        }
        tableView.reloadData()
    }

    private func addSummaryCard(
        title: String, count: Int, value: Double, currency: String, color: UIColor
    ) {
        let card = UIView()
        card.backgroundColor = Theme.current.cellBackground
        card.layer.cornerRadius = UIConstants.mediumCornerRadius

        let titleL = AppLabel(style: .footnote)
        titleL.apply(.footnote)
        titleL.textColor = Theme.current.secondaryText
        titleL.text = title
        titleL.numberOfLines = 1
        titleL.adjustsFontSizeToFitWidth = true
        titleL.minimumScaleFactor = 0.55
        titleL.allowsDefaultTighteningForTruncation = true

        let countL = AppLabel(style: .footnote)
        countL.apply(.footnoteLight)
        countL.textColor = Theme.current.secondaryText
        countL.text = R.string.global.abcProductCountFormat(count)
        countL.adjustsFontSizeToFitWidth = true
        countL.minimumScaleFactor = 0.75

        let valueL = AppLabel(style: .footnote)
        valueL.apply(.title3DemiBold)
        valueL.textColor = color
        valueL.adjustsFontSizeToFitWidth = true
        valueL.minimumScaleFactor = 0.55
        valueL.allowsDefaultTighteningForTruncation = true

        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = currency
        f.maximumFractionDigits = 0
        valueL.text = f.string(for: value)

        card.addSubview(titleL)
        card.addSubview(countL)
        card.addSubview(valueL)
        titleL.topToSuperview(offset: UIConstants.smallSpacing)
        titleL.leftToSuperview(offset: UIConstants.smallSpacing)
        titleL.rightToSuperview(offset: -UIConstants.smallSpacing)

        countL.topToBottom(of: titleL, offset: 2)
        countL.left(to: titleL)
        countL.right(to: titleL)

        valueL.topToBottom(of: countL, offset: 4)
        valueL.left(to: titleL)
        valueL.right(to: titleL)
        valueL.bottomToSuperview(offset: -UIConstants.smallSpacing)

        card.height(min: 84)

        summaryStack.addArrangedSubview(card)
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleRows.count + (hiddenBucketCCount > 0 ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == visibleRows.count, hiddenBucketCCount > 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ABCReportDetailViewController.showMoreIdentifier, for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            cell.textLabel?.text = R.string.global.commonShowMoreN(hiddenBucketCCount)
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = Theme.current.tabBarTint
            cell.textLabel?.font = Typography.bodyDemiBold
            return cell
        }
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ABCProductCell.identifier, for: indexPath)
            as! ABCProductCell
        let row = visibleRows[indexPath.row]
        let currency = R.string.global.commonCurrencyUAH()
        cell.configure(row: row, currency: currency)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == visibleRows.count, hiddenBucketCCount > 0 else { return }
        showAllBucketC = true
        tableView.reloadData()
    }
}
