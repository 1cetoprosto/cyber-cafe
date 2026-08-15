import Foundation

enum ReportListKind {
    case pl
    case abc
    case trends
}

struct ReportListItem {
    let kind: ReportListKind
    let titleKey: String
    let subtitleKey: String
    let symbol: String
}

protocol ReportsHubViewModelType {
    var currentPeriod: DashboardPeriod { get }
    var onPeriodChanged: (() -> Void)? { get set }
    var numberOfReports: Int { get }

    func report(at index: Int) -> ReportListItem
    func selectPeriod(at segmentIndex: Int)
    func segmentIndex(for period: DashboardPeriod) -> Int

    func buildPLReport() async -> PLReport
    func buildABCReport(rankingKey: ABCRankingKey) async -> ABCReport
    func buildTrendsReport(periodsBack: Int) async -> TrendsReport
}

final class ReportsHubViewModel: ReportsHubViewModelType {

    private let reportingService: FinanceReportingServiceProtocol
    private let referenceDateProvider: () -> Date

    private(set) var currentPeriod: DashboardPeriod = .month {
        didSet { onPeriodChanged?() }
    }

    var onPeriodChanged: (() -> Void)?

    private let reports: [ReportListItem] = [
        ReportListItem(
            kind: .pl,
            titleKey: "reportsPLTitle",
            subtitleKey: "reportsPLSubtitle",
            symbol: SystemImages.chartBar),
        ReportListItem(
            kind: .abc,
            titleKey: "reportsABCTitle",
            subtitleKey: "reportsABCSubtitle",
            symbol: SystemImages.chartPie),
        ReportListItem(
            kind: .trends,
            titleKey: "reportsTrendsTitle",
            subtitleKey: "reportsTrendsSubtitle",
            symbol: SystemImages.chartLine),
    ]

    var numberOfReports: Int { reports.count }

    init(
        reportingService: FinanceReportingServiceProtocol = FinanceReportingService(),
        referenceDateProvider: @escaping () -> Date = { Date() }
    ) {
        self.reportingService = reportingService
        self.referenceDateProvider = referenceDateProvider
    }

    func report(at index: Int) -> ReportListItem {
        reports[index]
    }

    func selectPeriod(at segmentIndex: Int) {
        switch segmentIndex {
        case 0: currentPeriod = .day
        case 1: currentPeriod = .week
        default: currentPeriod = .month
        }
    }

    func segmentIndex(for period: DashboardPeriod) -> Int {
        switch period {
        case .day: return 0
        case .week: return 1
        case .month: return 2
        }
    }

    func buildPLReport() async -> PLReport {
        await reportingService.fetchPLReport(
            period: currentPeriod,
            referenceDate: referenceDateProvider())
    }

    func buildABCReport(rankingKey: ABCRankingKey) async -> ABCReport {
        await reportingService.fetchABCReport(
            period: currentPeriod,
            referenceDate: referenceDateProvider(),
            rankingKey: rankingKey)
    }

    func buildTrendsReport(periodsBack: Int) async -> TrendsReport {
        await reportingService.fetchTrendsReport(
            periodicity: currentPeriod,
            periodsBack: max(2, periodsBack),
            referenceDate: referenceDateProvider())
    }
}
