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
            title: R.string.global.onboardingSlide1Title(),
            description: R.string.global.onboardingSlide1Desc(),
            imageName: "cart.fill"
        ),
        OnboardingSlide(
            title: R.string.global.onboardingSlide2Title(),
            description: R.string.global.onboardingSlide2Desc(),
            imageName: "creditcard.fill"
        ),
        OnboardingSlide(
            title: R.string.global.onboardingSlide3Title(),
            description: R.string.global.onboardingSlide3Desc(),
            imageName: "chart.bar.xaxis"
        ),
        OnboardingSlide(
            title: R.string.global.onboardingSlide4Title(),
            description: R.string.global.onboardingSlide4Desc(),
            imageName: "icloud.and.arrow.up.fill"
        )
    ]
}
