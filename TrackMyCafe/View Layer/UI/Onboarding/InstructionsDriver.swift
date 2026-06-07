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
        host.view.layoutIfNeeded()
        DispatchQueue.main.async { [weak self, weak host] in
            guard let self, let host else { return }
            self.controller.start(in: .currentWindow(of: host))
        }
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

        var superview = view.superview
        while let sView = superview {
            if let scrollView = sView as? UIScrollView {
                host?.view.layoutIfNeeded()
                scrollView.layoutIfNeeded()

                let frame = view.convert(view.bounds, to: scrollView)
                let targetMidY = frame.midY
                let desiredMidY = scrollView.bounds.height * 0.65

                let inset = scrollView.adjustedContentInset
                let minOffsetY = -inset.top
                let contentHeight = scrollView.contentLayoutGuide.layoutFrame.height
                let maxOffsetY = max(
                    -inset.top,
                    contentHeight - scrollView.bounds.height + inset.bottom
                )
                let rawOffsetY = scrollView.contentOffset.y + (targetMidY - desiredMidY)
                let clampedOffsetY = min(max(rawOffsetY, minOffsetY), maxOffsetY)
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: clampedOffsetY), animated: false)

                scrollView.layoutIfNeeded()
                host?.view.layoutIfNeeded()
                host?.view.window?.layoutIfNeeded()

                if let window = host?.view.window {
                    let safeTop = window.safeAreaInsets.top
                    let safeBottom = window.bounds.height - window.safeAreaInsets.bottom
                    let frameInWindow = view.convert(view.bounds, to: window)
                    let margin: CGFloat = 80
                    var correctedOffsetY = scrollView.contentOffset.y

                    if frameInWindow.minY < safeTop + margin {
                        correctedOffsetY -= (safeTop + margin - frameInWindow.minY)
                    } else if frameInWindow.maxY > safeBottom - margin {
                        correctedOffsetY += (frameInWindow.maxY - (safeBottom - margin))
                    }

                    let finalOffsetY = min(max(correctedOffsetY, minOffsetY), maxOffsetY)
                    if abs(finalOffsetY - scrollView.contentOffset.y) > 0.5 {
                        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: finalOffsetY), animated: false)
                        scrollView.layoutIfNeeded()
                        host?.view.layoutIfNeeded()
                        host?.view.window?.layoutIfNeeded()
                    }
                }
                break
            }
            superview = sView.superview
        }

        var coachMark = coachMarksController.helper.makeCoachMark(for: view)
        if let window = host?.view.window {
            let frameInWindow = view.convert(view.bounds, to: window)
            let safeTop = window.safeAreaInsets.top
            let safeBottom = window.bounds.height - window.safeAreaInsets.bottom

            let availableAbove = frameInWindow.minY - safeTop
            let availableBelow = safeBottom - frameInWindow.maxY

            coachMark.arrowOrientation = (availableBelow >= 220 || availableBelow >= availableAbove) ? .top : .bottom
        } else {
            coachMark.arrowOrientation = .top
        }
        coachMark.gapBetweenCoachMarkAndCutoutPath = 8
        coachMark.horizontalMargin = 24
        return coachMark
    }

    func coachMarksController(
        _ coachMarksController: CoachMarksController,
        coachMarkViewsAt index: Int,
        madeFrom coachMark: CoachMark
    ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
        let views = coachMarksController.helper.makeDefaultCoachViews(
            withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        let hintText = steps[index].title + "\n" + steps[index].message
        views.bodyView.hintLabel.text = hintText
        views.bodyView.nextLabel.text =
            (index == steps.count - 1) ? R.string.global.actionDone() : R.string.global.actionNext()

        let windowWidth = host?.view.window?.bounds.width ?? UIScreen.main.bounds.width
        let maxBodyWidth = max(280, windowWidth - (coachMark.horizontalMargin * 2))
        if !views.bodyView.constraints.contains(where: { $0.identifier == "coachMark.body.minWidth" }) {
            let c = views.bodyView.widthAnchor.constraint(greaterThanOrEqualToConstant: 240)
            c.priority = .required
            c.identifier = "coachMark.body.minWidth"
            c.isActive = true
        }
        if !views.bodyView.constraints.contains(where: { $0.identifier == "coachMark.body.maxWidth" }) {
            let c = views.bodyView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBodyWidth)
            c.priority = .required
            c.identifier = "coachMark.body.maxWidth"
            c.isActive = true
        }
        
        let hint = views.bodyView.hintLabel
        hint.isScrollEnabled = true
        hint.isEditable = false
        hint.isSelectable = false
        hint.showsVerticalScrollIndicator = false
        hint.showsHorizontalScrollIndicator = false
        hint.backgroundColor = .clear
        hint.textColor = UIColor.Main.text
        hint.font = Typography.body
        hint.textContainer.maximumNumberOfLines = 0
        hint.textContainer.lineBreakMode = .byWordWrapping
        
        hint.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        hint.setContentHuggingPriority(.defaultLow, for: .vertical)
        views.bodyView.nextLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        views.bodyView.nextLabel.setContentHuggingPriority(.required, for: .vertical)
        
        let windowHeight = host?.view.window?.bounds.height ?? UIScreen.main.bounds.height
        let maxHintHeight = min(260, windowHeight * 0.30)
        let minHintHeight: CGFloat = 44
        
        if !hint.constraints.contains(where: { $0.identifier == "coachMark.hint.maxHeight" }) {
            let c = hint.heightAnchor.constraint(lessThanOrEqualToConstant: maxHintHeight)
            c.priority = .required
            c.identifier = "coachMark.hint.maxHeight"
            c.isActive = true
        }
        
        if !hint.constraints.contains(where: { $0.identifier == "coachMark.hint.minHeight" }) {
            let c = hint.heightAnchor.constraint(greaterThanOrEqualToConstant: minHintHeight)
            c.priority = .required
            c.identifier = "coachMark.hint.minHeight"
            c.isActive = true
        }
        
        views.bodyView.setNeedsLayout()
        views.bodyView.layoutIfNeeded()
        
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
    ) { }

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
