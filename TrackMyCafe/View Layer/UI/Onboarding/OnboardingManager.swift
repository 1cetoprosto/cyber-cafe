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
        title: "Створити продаж",
        message: "Натисніть плюс, щоб додати щоденний продаж.",
        order: 1
      )
    ]
  )

  let orderDetailsFlow = OnboardingFlow(
    feature: .orderDetails,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "dateInput", title: "Дата продажу", message: "Переконайтесь, що дата правильна.",
        order: 1),
      OnboardingStepModel(
        targetKey: "typeInput", title: "Тип продажу",
        message: "Оберіть тип: зал/доставка/самовиніс.", order: 2),
      OnboardingStepModel(
        targetKey: "productsTable", title: "Кількість товарів",
        message: "Вкажіть кількість проданих одиниць.", order: 3),
      OnboardingStepModel(
        targetKey: "totalsRow", title: "Підсумок", message: "Перевірте загальну суму.", order: 4),
      OnboardingStepModel(
        targetKey: "cashInput", title: "Готівка", message: "Внесіть суму готівки за день.", order: 5
      ),
      OnboardingStepModel(
        targetKey: "cardInput", title: "Картка", message: "Внесіть надходження на картку.", order: 6
      ),
      OnboardingStepModel(
        targetKey: "saveButton", title: "Зберегти", message: "Збережіть щоденний продаж.", order: 7),
    ]
  )

  let costsFlow = OnboardingFlow(
    feature: .costs,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "navBarAddCost",
        title: "Додати витрату",
        message: "Натисніть плюс, щоб додати витрату.",
        order: 1
      )
    ]
  )

  let costDetailsFlow = OnboardingFlow(
    feature: .costDetails,
    versionTag: "1.0",
    steps: [
      OnboardingStepModel(
        targetKey: "dateInput", title: "Дата", message: "Вкажіть дату витрати.", order: 1),
      OnboardingStepModel(
        targetKey: "nameInput", title: "Назва", message: "Опишіть витрату.", order: 2),
      OnboardingStepModel(
        targetKey: "sumInput", title: "Сума", message: "Вкажіть суму у валюті додатку.", order: 3),
      OnboardingStepModel(
        targetKey: "saveButton", title: "Зберегти", message: "Збережіть витрату.", order: 4),
    ]
  )

  let settingsPriceFlow = OnboardingFlow(
    feature: .settingsPriceList,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "priceListCell", title: "Товари та ціни",
        message: "Спочатку додайте товари й ціни.", order: 1),
      OnboardingStepModel(
        targetKey: "navBarAddProduct", title: "Новий товар", message: "Додайте товар з ціною.",
        order: 2),
    ]
  )

  let settingsTypesFlow = OnboardingFlow(
    feature: .settingsTypes,
    versionTag: "1.2",
    steps: [
      OnboardingStepModel(
        targetKey: "typesCell", title: "Типи продажу",
        message: "Створіть типи та встановіть тип за замовчуванням.", order: 1)
    ]
  )

  OnboardingManager.shared.register(flow: ordersFlow)
  OnboardingManager.shared.register(flow: orderDetailsFlow)
  OnboardingManager.shared.register(flow: costsFlow)
  OnboardingManager.shared.register(flow: costDetailsFlow)
  OnboardingManager.shared.register(flow: settingsPriceFlow)
  OnboardingManager.shared.register(flow: settingsTypesFlow)
}
