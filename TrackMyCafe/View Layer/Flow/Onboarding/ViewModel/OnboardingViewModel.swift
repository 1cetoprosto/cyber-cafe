import UIKit

struct OnboardingSlide {
    let title: String
    let description: String
    let imageName: String
}

protocol OnboardingViewModelType {
    var slides: [OnboardingSlide] { get }
}

final class OnboardingViewModel: OnboardingViewModelType {
    let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Expenses Tracking",
            description: "Easily log and categorize your daily expenses to keep track of your spending.",
            imageName: "cart.fill"
        ),
        OnboardingSlide(
            title: "Income Management",
            description: "Monitor all your income streams in one place for better financial planning.",
            imageName: "creditcard.fill"
        ),
        OnboardingSlide(
            title: "Detailed Analytics",
            description: "Visualize your financial data with comprehensive charts and reports.",
            imageName: "chart.bar.xaxis"
        ),
        OnboardingSlide(
            title: "Multi-Currency Support",
            description: "Manage finances in multiple currencies seamlessly within the app.",
            imageName: "banknote.fill"
        )
    ]
}
