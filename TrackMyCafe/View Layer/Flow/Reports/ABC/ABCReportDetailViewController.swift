import TinyConstraints
import UIKit

final class ABCProductCell: UITableViewCell {

    static let identifier = "ABCProductCell"

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.current.secondaryBackground
        v.layer.cornerRadius = UIConstants.mediumCornerRadius
        return v
    }()

    private let bucketBadge: UILabel = {
        let l = UILabel()
        l.font = Typography.title3DemiBold
        l.textAlignment = .center
        l.textColor = .white
        l.layer.cornerRadius = 18
        l.layer.masksToBounds = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.bodyBold
        l.textColor = Theme.current.primaryText
        l.numberOfLines = 2
        return l
    }()

    private let qtyLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnote
        l.textColor = Theme.current.secondaryText
        return l
    }()

    private let salesLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.bodyMedium
        l.textColor = Theme.current.primaryText
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let shareLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnote
        l.textColor = Theme.current.secondaryText
        l.textAlignment = .right
        return l
    }()

    private let cumulativeLabel: UILabel = {
        let l = UILabel()
        l.font = Typography.footnoteLight
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

        qtyLabel.left(to: nameLabel)
        qtyLabel.topToBottom(of: nameLabel, offset: UIConstants.smallSpacing)
        qtyLabel.bottomToSuperview(offset: -UIConstants.mediumSpacing, relation: .equalOrLess)

        salesLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        salesLabel.rightToSuperview(offset: -UIConstants.mediumSpacing)
        salesLabel.leftToRight(
            of: nameLabel, offset: UIConstants.mediumSpacing, relation: .equalOrGreater)

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
        qtyLabel.text = "Qty: " + qtyStr

        let salesStr =
            ABCProductCell.currencyFormatter(currency: currency).string(for: row.sales) ?? ""
        salesLabel.text = salesStr

        shareLabel.text = String(format: "%.1f%%", row.sharePercent)
        cumulativeLabel.text = "Σ " + String(format: "%.1f%%", row.cumulativePercent)

        let (title, color) = ABCProductCell.bucketMeta(row.bucket)
        bucketBadge.text = title
        bucketBadge.backgroundColor = color
    }

    private static func bucketMeta(_ bucket: ABCBucket) -> (String, UIColor) {
        switch bucket {
        case .a: return ("A", .systemGreen)
        case .b: return ("B", .systemOrange)
        case .c: return ("C", .systemGray)
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

    private let rankingControl: UISegmentedControl = {
        let items = [
            NSLocalizedString("abcRankingSales", tableName: "Global", value: "Sales", comment: ""),
            NSLocalizedString(
                "abcRankingGross", tableName: "Global", value: "Gross Profit", comment: ""),
        ]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentTintColor = Theme.current.tabBarTint
        control.setTitleTextAttributes(
            [.foregroundColor: Theme.current.primaryText, .font: Typography.bodyMedium],
            for: .normal)
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: Typography.bodyBold],
            for: .selected)
        control.selectedSegmentIndex = 0
        return control
    }()

    private let summaryStack = UIStackView()

    private let tableView: UITableView = {
        let tableView = UITableView.standardList()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ABCProductCell.self, forCellReuseIdentifier: ABCProductCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
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

    private var rows: [ABCProductRow] = []
    private var countsByBucket: [ABCBucket: Int] = [:]

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
        title = NSLocalizedString(
            "reportsABCTitle", tableName: "Global", value: "ABC Analysis", comment: "")
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

        let tableHeader = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 104))
        let vStack = UIStackView(arrangedSubviews: [rankingControl, summaryStack])
        vStack.axis = .vertical
        vStack.spacing = UIConstants.mediumSpacing
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.layoutMargins = UIEdgeInsets(
            top: UIConstants.mediumSpacing,
            left: UIConstants.standardPadding,
            bottom: UIConstants.mediumSpacing,
            right: UIConstants.standardPadding)
        tableHeader.addSubview(vStack)
        vStack.edgesToSuperview()
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
            emptyStateLabel.text = NSLocalizedString(
                "commonLoading", tableName: "Global", value: "...", comment: "")
            let report = await sharedViewModel.buildABCReport(rankingKey: rankingKey)
            render(report: report)
        }
    }

    private func render(report: ABCReport) {
        rows = report.rows
        countsByBucket = report.countsByBucket

        summaryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let currency = NSLocalizedString(
            "commonCurrencyUAH", tableName: "Global", value: "₴", comment: "")
        let bucketSales = Dictionary(grouping: rows, by: { $0.bucket })
            .mapValues { $0.reduce(0) { $0 + $1.sales } }
        addSummaryCard(
            title: "A (0–80%)", count: countsByBucket[.a] ?? 0, value: bucketSales[.a] ?? 0,
            currency: currency, color: .systemGreen)
        addSummaryCard(
            title: "B (80–95%)", count: countsByBucket[.b] ?? 0, value: bucketSales[.b] ?? 0,
            currency: currency, color: .systemOrange)
        addSummaryCard(
            title: "C (95–100%)", count: countsByBucket[.c] ?? 0, value: bucketSales[.c] ?? 0,
            currency: currency, color: .systemGray)

        if rows.isEmpty {
            emptyStateLabel.text = NSLocalizedString(
                "abcEmpty", tableName: "Global", value: "No products in this period.", comment: "")
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
        card.backgroundColor = Theme.current.secondaryBackground
        card.layer.cornerRadius = UIConstants.mediumCornerRadius

        let titleL = UILabel()
        titleL.font = Typography.footnote
        titleL.textColor = Theme.current.secondaryText
        titleL.text = title
        titleL.numberOfLines = 2

        let countL = UILabel()
        countL.font = Typography.footnoteLight
        countL.textColor = Theme.current.secondaryText
        countL.text = String(
            format: NSLocalizedString(
                "abcProductCountFormat", tableName: "Global", value: "%d items", comment: ""), count
        )

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
        card.addSubview(countL)
        card.addSubview(valueL)
        titleL.topToSuperview(offset: UIConstants.smallSpacing)
        titleL.leftToSuperview(offset: UIConstants.smallSpacing)
        titleL.rightToSuperview(offset: -UIConstants.smallSpacing)

        countL.topToBottom(of: titleL, offset: 2)
        countL.left(to: titleL)
        countL.right(to: titleL)

        valueL.topToBottom(of: countL, offset: 4, relation: .equalOrGreater)
        valueL.left(to: titleL)
        valueL.right(to: titleL)
        valueL.bottomToSuperview(offset: -UIConstants.smallSpacing, relation: .equalOrLess)

        summaryStack.addArrangedSubview(card)
    }

    // MARK: - Table

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ABCProductCell.identifier, for: indexPath)
            as! ABCProductCell
        let row = rows[indexPath.row]
        let currency = NSLocalizedString(
            "commonCurrencyUAH", tableName: "Global", value: "₴", comment: "")
        cell.configure(row: row, currency: currency)
        return cell
    }
}
