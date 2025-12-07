import UIKit

enum OnboardingFeature: String, CaseIterable {
  case orders
  case orderDetails
  case costs
  case costDetails
  case settingsPriceList
  case settingsTypes
}

struct OnboardingStepModel {
  let targetKey: String
  let title: String
  let message: String
  let order: Int
}

struct OnboardingFlow {
  let feature: OnboardingFeature
  let versionTag: String
  let steps: [OnboardingStepModel]
}

protocol CoachMarksDriver {
  func present(
    on host: UIViewController, steps: [OnboardingStepModel], completion: @escaping () -> Void)
}

final class NoopCoachMarksDriver: CoachMarksDriver {
  func present(
    on host: UIViewController, steps: [OnboardingStepModel], completion: @escaping () -> Void
  ) {
    completion()
  }
}

final class OnboardingStorage {
  static let shared = OnboardingStorage()
  private let store = UserDefaults.standard

  func hasCompleted(feature: OnboardingFeature, versionTag: String) -> Bool {
    store.bool(forKey: key(feature, versionTag))
  }

  func markCompleted(feature: OnboardingFeature, versionTag: String) {
    store.set(true, forKey: key(feature, versionTag))
  }

  func resetAll(for versionTag: String) {
    for feature in OnboardingFeature.allCases {
      store.removeObject(forKey: key(feature, versionTag))
    }
    store.synchronize()
  }

  private func key(_ feature: OnboardingFeature, _ versionTag: String) -> String {
    "onboarding_\(feature.rawValue)_\(versionTag)"
  }
}

final class OnboardingManager {
  static let shared = OnboardingManager()

  private var flows: [OnboardingFeature: OnboardingFlow] = [:]
  private var driver: CoachMarksDriver = NoopCoachMarksDriver()
  private func appVersionTag() -> String {
    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
  }

  func resetForCurrentAppVersion() {
    OnboardingStorage.shared.resetAll(for: appVersionTag())
  }

  func configure(driver: CoachMarksDriver) {
    self.driver = driver
  }

  func register(flow: OnboardingFlow) {
    flows[flow.feature] = flow
  }

  func startIfNeeded(for feature: OnboardingFeature, on host: UIViewController) {
    guard let flow = flows[feature] else { return }
    if OnboardingStorage.shared.hasCompleted(feature: feature, versionTag: appVersionTag()) {
      return
    }
    driver.present(on: host, steps: flow.steps.sorted { $0.order < $1.order }) {
      OnboardingStorage.shared.markCompleted(feature: feature, versionTag: self.appVersionTag())
    }
  }
}

func buildDefaultOnboardingRegistry() {
  let ordersFlow = OnboardingFlow(
    feature: .orders,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "navBarAddOrder",
        title: R.string.global.onboardingOrdersAddTitle(),
        message: R.string.global.onboardingOrdersAddMessage(),
        order: 1
      )
    ]
  )

  let orderDetailsFlow = OnboardingFlow(
    feature: .orderDetails,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "dateInput", title: R.string.global.onboardingOrderDetailsDateTitle(), message: R.string.global.onboardingOrderDetailsDateMessage(),
        order: 1),
      OnboardingStepModel(
        targetKey: "typeInput", title: R.string.global.onboardingOrderDetailsTypeTitle(),
        message: R.string.global.onboardingOrderDetailsTypeMessage(), order: 2),
      OnboardingStepModel(
        targetKey: "productsTable", title: R.string.global.onboardingOrderDetailsProductsTitle(),
        message: R.string.global.onboardingOrderDetailsProductsMessage(), order: 3),
      OnboardingStepModel(
        targetKey: "totalsRow", title: R.string.global.onboardingOrderDetailsTotalsTitle(), message: R.string.global.onboardingOrderDetailsTotalsMessage(), order: 4),
      OnboardingStepModel(
        targetKey: "cashInput", title: R.string.global.onboardingOrderDetailsCashTitle(), message: R.string.global.onboardingOrderDetailsCashMessage(), order: 5
      ),
      OnboardingStepModel(
        targetKey: "cardInput", title: R.string.global.onboardingOrderDetailsCardTitle(), message: R.string.global.onboardingOrderDetailsCardMessage(), order: 6
      ),
      OnboardingStepModel(
        targetKey: "saveButton", title: R.string.global.onboardingOrderDetailsSaveTitle(), message: R.string.global.onboardingOrderDetailsSaveMessage(), order: 7),
    ]
  )

  let costsFlow = OnboardingFlow(
    feature: .costs,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "navBarAddCost",
        title: R.string.global.onboardingCostsAddTitle(),
        message: R.string.global.onboardingCostsAddMessage(),
        order: 1
      )
    ]
  )

  let costDetailsFlow = OnboardingFlow(
    feature: .costDetails,
    versionTag: "1.0",
    steps: [
      OnboardingStepModel(
        targetKey: "dateInput", title: R.string.global.onboardingCostDetailsDateTitle(), message: R.string.global.onboardingCostDetailsDateMessage(), order: 1),
      OnboardingStepModel(
        targetKey: "nameInput", title: R.string.global.onboardingCostDetailsNameTitle(), message: R.string.global.onboardingCostDetailsNameMessage(), order: 2),
      OnboardingStepModel(
        targetKey: "sumInput", title: R.string.global.onboardingCostDetailsSumTitle(), message: R.string.global.onboardingCostDetailsSumMessage(), order: 3),
      OnboardingStepModel(
        targetKey: "saveButton", title: R.string.global.onboardingCostDetailsSaveTitle(), message: R.string.global.onboardingCostDetailsSaveMessage(), order: 4),
    ]
  )

  let settingsPriceFlow = OnboardingFlow(
    feature: .settingsPriceList,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "priceListCell", title: R.string.global.onboardingSettingsPriceListTitle(),
        message: R.string.global.onboardingSettingsPriceListMessage(), order: 1),
      OnboardingStepModel(
        targetKey: "navBarAddProduct", title: R.string.global.onboardingSettingsAddProductTitle(), message: R.string.global.onboardingSettingsAddProductMessage(),
        order: 2),
    ]
  )

  let settingsTypesFlow = OnboardingFlow(
    feature: .settingsTypes,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "typesCell", title: R.string.global.onboardingSettingsTypesTitle(),
        message: R.string.global.onboardingSettingsTypesMessage(), order: 1)
    ]
  )

  OnboardingManager.shared.register(flow: ordersFlow)
  OnboardingManager.shared.register(flow: orderDetailsFlow)
  OnboardingManager.shared.register(flow: costsFlow)
  OnboardingManager.shared.register(flow: costDetailsFlow)
  OnboardingManager.shared.register(flow: settingsPriceFlow)
  OnboardingManager.shared.register(flow: settingsTypesFlow)
}
