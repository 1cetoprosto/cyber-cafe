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

        // Scroll to view if needed BEFORE creating the coach mark
        // Try to find a parent UIScrollView and scroll to the target view
        var superview = view.superview
        while let sView = superview {
            if let scrollView = sView as? UIScrollView {
                let frame = view.convert(view.bounds, to: scrollView)
                let paddedFrame = frame.insetBy(dx: 0, dy: -40)
                scrollView.scrollRectToVisible(paddedFrame, animated: false)
                scrollView.layoutIfNeeded()
                break
            }
            superview = sView.superview
        }

        var coachMark = coachMarksController.helper.makeCoachMark(for: view)

        // Removed forced orientation for productsTable as auto-scroll handles visibility

        return coachMark
    }

    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        coachMarkViewsAt index: Int,
        madeFrom coachMark: CoachMark
    ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
        let views = coachMarksController.helper.makeDefaultCoachViews(
            withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        views.bodyView.hintLabel.text = steps[index].title + "\n" + steps[index].message
        views.bodyView.nextLabel.text =
        (index == steps.count - 1) ? R.string.global.actionDone() : R.string.global.actionNext()
        return (views.bodyView, views.arrowView)
    }

    func coachMarksController(
        _ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool
    ) {
        completion?()
    }

    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        willShow coachMark: CoachMark,
        at index: Int
    ) {
        print("InstructionsDriver: willShow step \(index)")
        guard let view = resolveView(for: steps[index].targetKey) else {
            print("InstructionsDriver: View not found for key \(steps[index].targetKey)")
            return
        }

        // Try to find a parent UIScrollView and scroll to the target view
        var superview = view.superview
        while let sView = superview {
            if let scrollView = sView as? UIScrollView {
                print("InstructionsDriver: Found scroll view for \(steps[index].targetKey)")
                let frame = view.convert(view.bounds, to: scrollView)
                // Add vertical padding to make sure it's not stick to edges
                let paddedFrame = frame.insetBy(dx: 0, dy: -40)

                // Use animated: false to ensure immediate update before coach mark is drawn
                scrollView.scrollRectToVisible(paddedFrame, animated: false)
                scrollView.layoutIfNeeded()
                print("InstructionsDriver: Scrolled to \(paddedFrame)")
                break
            }
            superview = sView.superview
        }
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
