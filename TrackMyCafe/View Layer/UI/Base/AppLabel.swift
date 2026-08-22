import UIKit

final class AppLabel: UILabel {
    enum Style {
        case largeTitle
        case largeTitleBold
        case largeTitleBoldValue
        case title1
        case title1Bold
        case title1BoldValue
        case title2DemiBold
        case title3
        case title3DemiBold
        case title3DemiBoldValue
        case title3Value
        case headline
        case body
        case bodyMedium
        case bodyDemiBold
        case bodyBold
        case bodyBoldValue
        case bodyMultiline
        case bodyValue
        case callout
        case calloutDemi
        case calloutDemiValue
        case footnote
        case footnoteLight
        case footnoteValue
        case kpiTitle
        case kpiValue
        case kpiFooter
        case balanceTitle
        case balanceValue
    }

    private struct Configuration {
        let font: UIFont
        let numberOfLines: Int
        let lineBreakMode: NSLineBreakMode
        let textColor: UIColor
        let adjustsFontSizeToFitWidth: Bool
        let minimumScaleFactor: CGFloat
        let allowsDefaultTighteningForTruncation: Bool

        init(
            font: UIFont,
            numberOfLines: Int,
            lineBreakMode: NSLineBreakMode,
            textColor: UIColor,
            adjustsFontSizeToFitWidth: Bool = false,
            minimumScaleFactor: CGFloat = 1,
            allowsDefaultTighteningForTruncation: Bool = false
        ) {
            self.font = font
            self.numberOfLines = numberOfLines
            self.lineBreakMode = lineBreakMode
            self.textColor = textColor
            self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
            self.minimumScaleFactor = minimumScaleFactor
            self.allowsDefaultTighteningForTruncation = allowsDefaultTighteningForTruncation
        }
    }

    private static let configurations: [Style: Configuration] = [
        .largeTitle: Configuration(
            font: Typography.largeTitle,
            numberOfLines: 0,
            lineBreakMode: .byWordWrapping,
            textColor: UIColor.Main.text
        ),
        .largeTitleBold: Configuration(
            font: Typography.largeTitleBold,
            numberOfLines: 2,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .largeTitleBoldValue: Configuration(
            font: Typography.largeTitleBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.6,
            allowsDefaultTighteningForTruncation: true
        ),
        .title1: Configuration(
            font: Typography.title1,
            numberOfLines: 2,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .title1Bold: Configuration(
            font: Typography.title1Bold,
            numberOfLines: 2,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .title1BoldValue: Configuration(
            font: Typography.title1Bold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.6,
            allowsDefaultTighteningForTruncation: true
        ),
        .title2DemiBold: Configuration(
            font: Typography.title2DemiBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .title3: Configuration(
            font: Typography.title3,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .title3DemiBold: Configuration(
            font: Typography.title3DemiBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .title3DemiBoldValue: Configuration(
            font: Typography.title3DemiBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.7
        ),
        .title3Value: Configuration(
            font: Typography.title3,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.7
        ),
        .headline: Configuration(
            font: Typography.headline,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .body: Configuration(
            font: Typography.body,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .bodyMedium: Configuration(
            font: Typography.bodyMedium,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .bodyDemiBold: Configuration(
            font: Typography.bodyDemiBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .bodyBold: Configuration(
            font: Typography.bodyBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .bodyBoldValue: Configuration(
            font: Typography.bodyBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.8
        ),
        .bodyMultiline: Configuration(
            font: Typography.body,
            numberOfLines: 0,
            lineBreakMode: .byWordWrapping,
            textColor: UIColor.Main.text
        ),
        .bodyValue: Configuration(
            font: Typography.body,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.8
        ),
        .callout: Configuration(
            font: Typography.callout,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .calloutDemi: Configuration(
            font: Typography.calloutDemi,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .calloutDemiValue: Configuration(
            font: Typography.calloutDemi,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.7,
            allowsDefaultTighteningForTruncation: true
        ),
        .footnote: Configuration(
            font: Typography.footnote,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .footnoteLight: Configuration(
            font: Typography.footnoteLight,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text
        ),
        .footnoteValue: Configuration(
            font: Typography.footnote,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.85
        ),
        .kpiTitle: Configuration(
            font: Typography.footnote,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text.alpha(0.7),
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.7,
            allowsDefaultTighteningForTruncation: true
        ),
        .kpiValue: Configuration(
            font: Typography.title3DemiBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.6,
            allowsDefaultTighteningForTruncation: true
        ),
        .kpiFooter: Configuration(
            font: Typography.footnote,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text.alpha(0.7),
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.85
        ),
        .balanceTitle: Configuration(
            font: Typography.footnote,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text.alpha(0.7)
        ),
        .balanceValue: Configuration(
            font: Typography.title3DemiBold,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail,
            textColor: UIColor.Main.text,
            adjustsFontSizeToFitWidth: true,
            minimumScaleFactor: 0.7
        ),
    ]

    init(style: Style) {
        super.init(frame: .zero)
        apply(style)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        apply(.footnote)
    }

    func apply(_ style: Style) {
        adjustsFontForContentSizeCategory = true
        guard let configuration = Self.configurations[style] else { return }
        font = configuration.font
        numberOfLines = configuration.numberOfLines
        lineBreakMode = configuration.lineBreakMode
        textColor = configuration.textColor
        adjustsFontSizeToFitWidth = configuration.adjustsFontSizeToFitWidth
        minimumScaleFactor = configuration.minimumScaleFactor
        allowsDefaultTighteningForTruncation =
            configuration
            .allowsDefaultTighteningForTruncation
    }
}
