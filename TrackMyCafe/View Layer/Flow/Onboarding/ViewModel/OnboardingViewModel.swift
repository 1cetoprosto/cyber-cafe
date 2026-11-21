//
//  OnboardingViewModel.swift
//  TrackMyCafe
//

import Foundation

// MARK: - Shared demo money (onboarding + paywall)

enum CafeDemoMoneyScenario {
    case uah
    case usd

    static func resolve(
        settingsSymbol: String? = RequestManager.shared.settings?.currencySymbol,
        locale: Locale = .current
    ) -> CafeDemoMoneyScenario {
        if let settingsSymbol, !settingsSymbol.isEmpty {
            if settingsSymbol == DefaultValues.dollarSymbol { return .usd }
            if settingsSymbol == DefaultValues.currencySymbol { return .uah }
        }

        if let code = locale.currencyCode {
            if code == "UAH" { return .uah }
            if code == "USD" { return .usd }
        }

        if locale.languageCode == "uk" { return .uah }
        return .usd
    }

    var currencyCode: String {
        switch self {
        case .uah: return "UAH"
        case .usd: return "USD"
        }
    }

    var amounts: (
        receipt: Double,
        sales: Double,
        supplies: Double,
        rent: Double,
        payroll: Double,
        left: Double
    ) {
        switch self {
        case .uah:
            return (220, 12_400, 4_800, 1_200, 3_500, 2_900)
        case .usd:
            return (9.5, 980, 320, 95, 280, 285)
        }
    }

    struct FormattedSummary {
        let receipt: String
        let sales: String
        let supplies: String
        let rent: String
        let payroll: String
        let costsTotal: String
        let left: String
        let comparison: String
    }

    func formattedSummary(locale: Locale = .current) -> FormattedSummary {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        if currencyCode == "USD" {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
        } else {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }

        func format(_ value: Double) -> String {
            formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        }

        let a = amounts
        let sales = format(a.sales)
        let left = format(a.left)
        return FormattedSummary(
            receipt: format(a.receipt),
            sales: sales,
            supplies: format(a.supplies),
            rent: format(a.rent),
            payroll: format(a.payroll),
            costsTotal: format(a.supplies + a.rent + a.payroll),
            left: left,
            comparison: "\(sales)  →  \(left)"
        )
    }
}

// MARK: - Models

enum OnboardingSlideKind {
    case receiptToShift
    case expenses
    case whatsLeft
}

enum OnboardingHeroStyle {
    case sales
    case mutedSales
    case leftover
}

enum OnboardingDemoLineTone {
    case neutral
    case positive
    case negative
    case emphasized
}

struct OnboardingDemoLine {
    let title: String
    let value: String
    let tone: OnboardingDemoLineTone
    let showsDividerAfter: Bool

    init(
        title: String,
        value: String,
        tone: OnboardingDemoLineTone = .neutral,
        showsDividerAfter: Bool = false
    ) {
        self.title = title
        self.value = value
        self.tone = tone
        self.showsDividerAfter = showsDividerAfter
    }
}

struct OnboardingSlide {
    let kind: OnboardingSlideKind
    let title: String
    let description: String
    let buttonTitle: String
    let heroValue: String?
    let heroCaption: String?
    let heroStyle: OnboardingHeroStyle
    let comparisonText: String?
    let lines: [OnboardingDemoLine]
}

protocol OnboardingViewModelType {
    var slides: [OnboardingSlide] { get }
}

final class OnboardingViewModel: OnboardingViewModelType {

    let slides: [OnboardingSlide]

    init(
        settingsCurrencySymbol: String? = RequestManager.shared.settings?.currencySymbol,
        locale: Locale = .current
    ) {
        let summary = CafeDemoMoneyScenario.resolve(
            settingsSymbol: settingsCurrencySymbol,
            locale: locale
        ).formattedSummary(locale: locale)

        slides = [
            OnboardingSlide(
                kind: .receiptToShift,
                title: R.string.global.onboardingSlide1Title(),
                description: R.string.global.onboardingSlide1Desc(),
                buttonTitle: R.string.global.actionNext(),
                heroValue: summary.sales,
                heroCaption: R.string.global.onboardingDemoSalesToday(),
                heroStyle: .sales,
                comparisonText: nil,
                lines: [
                    OnboardingDemoLine(
                        title: R.string.global.onboardingDemoCoffeeCroissant(),
                        value: summary.receipt
                    )
                ]
            ),
            OnboardingSlide(
                kind: .expenses,
                title: R.string.global.onboardingSlide2Title(),
                description: R.string.global.onboardingSlide2Desc(),
                buttonTitle: R.string.global.onboardingShowWhatsLeft(),
                heroValue: summary.sales,
                heroCaption: R.string.global.onboardingDemoWasSales(),
                heroStyle: .mutedSales,
                comparisonText: nil,
                lines: [
                    OnboardingDemoLine(
                        title: R.string.global.onboardingDemoSupplies(),
                        value: "−\(summary.supplies)"
                    ),
                    OnboardingDemoLine(
                        title: R.string.global.onboardingDemoRentDay(),
                        value: "−\(summary.rent)"
                    ),
                    OnboardingDemoLine(
                        title: R.string.global.onboardingDemoPayroll(),
                        value: "−\(summary.payroll)"
                    )
                ]
            ),
            OnboardingSlide(
                kind: .whatsLeft,
                title: R.string.global.onboardingSlide3Title(),
                description: R.string.global.onboardingSlide3Desc(summary.sales, summary.left),
                buttonTitle: R.string.global.onboardingGetStarted(),
                heroValue: summary.left,
                heroCaption: R.string.global.hubBigNetLabel(),
                heroStyle: .leftover,
                comparisonText: summary.comparison,
                lines: [
                    OnboardingDemoLine(
                        title: R.string.global.hubBigSalesLabel(),
                        value: "+\(summary.sales)",
                        tone: .positive
                    ),
                    OnboardingDemoLine(
                        title: R.string.global.hubBigCostsLabel(),
                        value: "−\(summary.costsTotal)",
                        tone: .negative,
                        showsDividerAfter: true
                    ),
                    OnboardingDemoLine(
                        title: R.string.global.hubBigNetLabel(),
                        value: summary.left,
                        tone: .emphasized
                    )
                ]
            )
        ]
    }
}
