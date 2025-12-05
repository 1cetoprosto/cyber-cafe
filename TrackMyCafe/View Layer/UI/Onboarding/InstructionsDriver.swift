import UIKit

#if canImport(Instructions)
  import Instructions

  final class InstructionsDriver: NSObject, CoachMarksDriver, CoachMarksControllerDataSource,
    CoachMarksControllerDelegate
  {
    private let controller = CoachMarksController()
    private weak var host: UIViewController?
    private var steps: [OnboardingStepModel] = []
    private var completion: (() -> Void)?

    func present(
      on host: UIViewController, steps: [OnboardingStepModel], completion: @escaping () -> Void
    ) {
      self.host = host
      let filtered = steps.sorted { $0.order < $1.order }.filter {
        resolveView(for: $0.targetKey) != nil
      }
      if filtered.isEmpty { return }
      self.steps = filtered
      self.completion = completion
      controller.dataSource = self
      controller.delegate = self
      controller.start(in: .currentWindow(of: host))
    }

    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
      steps.count
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int)
      -> CoachMark
    {
      guard let view = resolveView(for: steps[index].targetKey) else {
        return coachMarksController.helper.makeCoachMark()
      }
      return coachMarksController.helper.makeCoachMark(for: view)
    }

    func coachMarksController(
      _ coachMarksController: CoachMarksController,
      coachMarkViewsAt index: Int,
      madeFrom coachMark: CoachMark
    ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
      let views = coachMarksController.helper.makeDefaultCoachViews(
        withArrow: true, arrowOrientation: coachMark.arrowOrientation)
      views.bodyView.hintLabel.text = steps[index].title + "\n" + steps[index].message
      views.bodyView.nextLabel.text = (index == steps.count - 1) ? "Done" : "Next"
      return (views.bodyView, views.arrowView)
    }

    func coachMarksController(
      _ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool
    ) {
      completion?()
    }

    private func resolveView(for key: String) -> UIView? {
      // 1) Search in controller's root view hierarchy
      if let container = host?.view,
        let found = findView(withAccessibilityIdentifier: key, in: container)
      {
        return found
      }
      // 2) Search in navigation controller's view (includes navigation bar)
      if let navView = host?.navigationController?.view,
        let found = findView(withAccessibilityIdentifier: key, in: navView)
      {
        return found
      }
      // 3) Directly check common bar button custom views
      if key == "navBarAddOrder" || key == "navBarAddCost" || key == "navBarAddProduct" {
        if let custom = host?.navigationItem.rightBarButtonItem?.customView,
          custom.accessibilityIdentifier == key
        {
          return custom
        }
      }
      // 4) As a last resort, search the whole window
      if let window = host?.view.window {
        for sub in window.subviews {
          if let found = findView(withAccessibilityIdentifier: key, in: sub) { return found }
        }
      }
      return nil
    }

    private func findView(withAccessibilityIdentifier id: String, in root: UIView) -> UIView? {
      if root.accessibilityIdentifier == id { return root }
      for sub in root.subviews {
        if let found = findView(withAccessibilityIdentifier: id, in: sub) { return found }
      }
      return nil
    }
  }
#endif
