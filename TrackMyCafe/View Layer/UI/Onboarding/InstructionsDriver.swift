import UIKit

#if canImport(Instructions)
    import Instructions

    final class InstructionsDriver: NSObject, Loggable, CoachMarksDriver, CoachMarksControllerDataSource,
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

        func coachMarksController(
            _ coachMarksController: CoachMarksController, coachMarkAt index: Int
        ) -> CoachMark {
            let key = steps[index].targetKey
            logger.debug("coachMarkAt index=\(index), key=\(key)")

            guard let host else { return coachMarksController.helper.makeCoachMark() }

            if let view = resolveView(for: key) {
                scrollToReveal(view: view)
            }

            host.view.layoutIfNeeded()
            host.view.window?.layoutIfNeeded()

            if let view = resolveView(for: key), view.window != nil {
                var coachMark = coachMarksController.helper.makeCoachMark(for: view)
                coachMark.gapBetweenCoachMarkAndCutoutPath = 8
                coachMark.horizontalMargin = 24
                coachMark.arrowOrientation = preferredArrowOrientation(for: view, host: host)
                return coachMark
            }

            guard let window = host.view.window else {
                logger.error("coachMarkAt: window missing. key=\(key)")
                return coachMarksController.helper.makeCoachMark()
            }

            let fallbackFrame = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 1, height: 1)
            var coachMark = coachMarksController.helper.makeCoachMark(forFrame: fallbackFrame, in: window)
            coachMark.gapBetweenCoachMarkAndCutoutPath = 8
            coachMark.horizontalMargin = 24
            coachMark.arrowOrientation = .top
            return coachMark
        }

        func coachMarksController(
            _ coachMarksController: CoachMarksController,
            coachMarkViewsAt index: Int,
            madeFrom coachMark: CoachMark
        ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
            logger.debug("coachMarkViewsAt index=\(index), key=\(steps[index].targetKey)")

            let views = coachMarksController.helper.makeDefaultCoachViews(
                withArrow: true, arrowOrientation: coachMark.arrowOrientation
            )

            views.bodyView.hintLabel.text = steps[index].title + "\n" + steps[index].message
            views.bodyView.nextLabel.text =
                (index == steps.count - 1) ? R.string.global.actionDone() : R.string.global.actionNext()

            if let body = views.bodyView as? CoachMarkBodyDefaultView {
                body.hintLabel.textColor = .white
                body.nextLabel.textColor = .white
                body.background.innerColor = UIColor.black.withAlphaComponent(0.85)
                body.background.borderColor = UIColor.white.withAlphaComponent(0.12)
            }

            let windowWidth = host?.view.window?.bounds.width ?? UIScreen.main.bounds.width
            let maxBodyWidth = max(280, windowWidth - (coachMark.horizontalMargin * 2))

            if !views.bodyView.constraints.contains(where: { $0.identifier == "coachMark.body.minWidth" }) {
                let constraint = views.bodyView.widthAnchor.constraint(greaterThanOrEqualToConstant: 240)
                constraint.priority = .required
                constraint.identifier = "coachMark.body.minWidth"
                constraint.isActive = true
            }

            if !views.bodyView.constraints.contains(where: { $0.identifier == "coachMark.body.maxWidth" }) {
                let constraint = views.bodyView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBodyWidth)
                constraint.priority = .required
                constraint.identifier = "coachMark.body.maxWidth"
                constraint.isActive = true
            }

            let hint = views.bodyView.hintLabel
            hint.isScrollEnabled = true
            hint.isEditable = false
            hint.isSelectable = false
            hint.showsVerticalScrollIndicator = false
            hint.showsHorizontalScrollIndicator = false
            hint.backgroundColor = .clear
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
                let constraint = hint.heightAnchor.constraint(lessThanOrEqualToConstant: maxHintHeight)
                constraint.priority = .required
                constraint.identifier = "coachMark.hint.maxHeight"
                constraint.isActive = true
            }

            if !hint.constraints.contains(where: { $0.identifier == "coachMark.hint.minHeight" }) {
                let constraint = hint.heightAnchor.constraint(greaterThanOrEqualToConstant: minHintHeight)
                constraint.priority = .required
                constraint.identifier = "coachMark.hint.minHeight"
                constraint.isActive = true
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
            willLoadCoachMarkAt index: Int
        ) -> Bool {
            let key = steps[index].targetKey
            logger.debug("willLoadCoachMarkAt index=\(index), key=\(key)")

            guard let host, let window = host.view.window else { return true }

            if let view = resolveView(for: key) {
                scrollToReveal(view: view)
                host.view.layoutIfNeeded()
                window.layoutIfNeeded()
            }

            return true
        }

        func coachMarksController(
            _ coachMarksController: CoachMarksController,
            willShow coachMark: inout CoachMark,
            beforeChanging change: ConfigurationChange,
            at index: Int
        ) {
            guard let host, let window = host.view.window else { return }
            guard let cutoutBounds = coachMark.cutoutPath?.bounds else { return }

            let safeBounds = window.bounds.inset(by: window.safeAreaInsets)
            let spaceAbove = cutoutBounds.minY - safeBounds.minY
            let spaceBelow = safeBounds.maxY - cutoutBounds.maxY
            coachMark.arrowOrientation = (spaceBelow >= spaceAbove) ? .top : .bottom
        }

        private func scrollToReveal(view: UIView) {
            let padding: CGFloat = 20
            if let cell = superview(of: UITableViewCell.self, from: view),
                let tableView = superview(of: UITableView.self, from: cell),
                let indexPath = tableView.indexPath(for: cell)
            {
                let rectInTable = cell.convert(cell.bounds, to: tableView)
                let visible = tableView.bounds.inset(by: UIEdgeInsets(
                    top: padding, left: 0, bottom: padding, right: 0))
                if visible.contains(rectInTable) {
                    tableView.layoutIfNeeded()
                    return
                }

                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                var offset = tableView.contentOffset
                offset.y = max(-tableView.adjustedContentInset.top, offset.y - padding)
                tableView.setContentOffset(offset, animated: false)
                tableView.layoutIfNeeded()
                return
            }

            if let cell = superview(of: UICollectionViewCell.self, from: view),
                let collectionView = superview(of: UICollectionView.self, from: cell),
                let indexPath = collectionView.indexPath(for: cell)
            {
                let rectInCollection = cell.convert(cell.bounds, to: collectionView)
                let visible = collectionView.bounds.inset(by: UIEdgeInsets(
                    top: padding, left: 0, bottom: padding, right: 0))
                if visible.contains(rectInCollection) {
                    collectionView.layoutIfNeeded()
                    return
                }

                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                var offset = collectionView.contentOffset
                offset.y = max(-collectionView.adjustedContentInset.top, offset.y - padding)
                collectionView.setContentOffset(offset, animated: false)
                collectionView.layoutIfNeeded()
            }

            if let scrollView = superview(of: UIScrollView.self, from: view) {
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
                scrollView.setContentOffset(
                    CGPoint(x: scrollView.contentOffset.x, y: clampedOffsetY),
                    animated: false
                )

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
                        scrollView.setContentOffset(
                            CGPoint(x: scrollView.contentOffset.x, y: finalOffsetY),
                            animated: false
                        )
                        scrollView.layoutIfNeeded()
                        host?.view.layoutIfNeeded()
                        host?.view.window?.layoutIfNeeded()
                    }
                }
            }
        }

        private func superview<T: UIView>(of type: T.Type, from view: UIView) -> T? {
            var current: UIView? = view
            while let currentView = current {
                if let match = currentView as? T { return match }
                current = currentView.superview
            }
            return nil
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
                    if let found = findView(withAccessibilityIdentifier: key, in: sub) {
                        return found
                        return found
                    }
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

        private func preferredArrowOrientation(for view: UIView, host: UIViewController) -> CoachMarkArrowOrientation {
            guard let window = host.view.window else { return .top }

            let frameInWindow = view.convert(view.bounds, to: window)
            let safeTop = window.safeAreaInsets.top
            let safeBottom = window.bounds.height - window.safeAreaInsets.bottom

            let availableAbove = frameInWindow.minY - safeTop
            let availableBelow = safeBottom - frameInWindow.maxY

            return (availableBelow >= 220 || availableBelow >= availableAbove) ? .top : .bottom
        }
    }
#endif
