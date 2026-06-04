import UIKit

#if canImport(Instructions)
    import Instructions

    final class InstructionsDriver: NSObject, Loggable, CoachMarksDriver,
        CoachMarksControllerDataSource,
        CoachMarksControllerDelegate
    {
        private let controller = CoachMarksController()
        private weak var host: UIViewController?
        private var steps: [OnboardingStepModel] = []
        private var completion: (() -> Void)?

        func present(
            on host: UIViewController, steps: [OnboardingStepModel],
            completion: @escaping () -> Void
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

        func coachMarksController(
            _ coachMarksController: CoachMarksController, coachMarkAt index: Int
        )
            -> CoachMark
        {
            let key = steps[index].targetKey
            logger.debug("coachMarkAt index=\(index), key=\(key)")
            guard let host, let window = host.view.window else {
                logger.error("coachMarkAt: host/window missing. key=\(key)")
                return coachMarksController.helper.makeCoachMark()
            }

            if let view = resolveView(for: key), view.window != nil {
                return coachMarksController.helper.makeCoachMark(for: view)
            }

            let fallbackFrame = CGRect(
                x: window.bounds.midX,
                y: window.bounds.midY,
                width: 1,
                height: 1
            )
            return coachMarksController.helper.makeCoachMark(forFrame: fallbackFrame, in: window)
        }

        func coachMarksController(
            _ coachMarksController: CoachMarksController,
            coachMarkViewsAt index: Int,
            madeFrom coachMark: CoachMark
        ) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
            logger.debug("coachMarkViewsAt index=\(index), key=\(steps[index].targetKey)")
            let views = coachMarksController.helper.makeDefaultCoachViews(
                withArrow: true, arrowOrientation: coachMark.arrowOrientation)
            views.bodyView.hintLabel.text = steps[index].title + "\n" + steps[index].message
            views.bodyView.nextLabel.text =
                (index == steps.count - 1)
                ? R.string.global.actionDone() : R.string.global.actionNext()
            views.bodyView.isHidden = false
            views.bodyView.alpha = 1
            if let body = views.bodyView as? CoachMarkBodyDefaultView {
                body.hintLabel.textColor = .white
                body.nextLabel.textColor = .white
                body.background.innerColor = UIColor.black.withAlphaComponent(0.85)
                body.background.borderColor = UIColor.white.withAlphaComponent(0.12)
            }
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
            let key = self.steps[index].targetKey
            logger.debug("willLoadCoachMarkAt index=\(index), key=\(key)")
            guard let host = self.host, let window = host.view.window else { return true }
            if let view = self.resolveView(for: key) {
                self.scrollToReveal(view: view)
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
            let key = self.steps[index].targetKey
            let cutout = coachMark.cutoutPath?.bounds.debugDescription ?? "nil"
            logger.debug(
                "willShow index=\(index), key=\(key), change=\(String(describing: change)), cutout=\(cutout)"
            )
            guard let host = self.host, let window = host.view.window else { return }
            guard let cutoutBounds = coachMark.cutoutPath?.bounds else { return }

            let safeBounds = window.bounds.inset(by: window.safeAreaInsets)
            let spaceAbove = cutoutBounds.minY - safeBounds.minY
            let spaceBelow = safeBounds.maxY - cutoutBounds.maxY
            coachMark.arrowOrientation = (spaceBelow >= spaceAbove) ? .top : .bottom
        }

        private func updateToFallbackCenter(
            in window: UIWindow, coachMarksController: CoachMarksController
        ) {
            coachMarksController.helper.updateCurrentCoachMark { coachMark, converter in
                let frame = CGRect(
                    x: window.bounds.midX, y: window.bounds.midY, width: 1, height: 1)
                let converted = converter.convert(rect: frame, from: window)
                coachMark.cutoutPath = UIBezierPath(
                    roundedRect: converted.insetBy(dx: -4, dy: -4),
                    byRoundingCorners: .allCorners,
                    cornerRadii: CGSize(width: 4, height: 4)
                )
                coachMark.pointOfInterest = CGPoint(x: converted.midX, y: converted.midY)
            }
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
                return
            }

            if let scrollView = superview(of: UIScrollView.self, from: view) {
                let rect = view.convert(view.bounds, to: scrollView)
                let visible = scrollView.bounds.inset(by: UIEdgeInsets(
                    top: padding, left: padding, bottom: padding, right: padding))
                if visible.contains(rect) {
                    scrollView.layoutIfNeeded()
                    return
                }

                var targetOffset = scrollView.contentOffset
                if rect.minY < visible.minY {
                    targetOffset.y -= (visible.minY - rect.minY)
                } else if rect.maxY > visible.maxY {
                    targetOffset.y += (rect.maxY - visible.maxY)
                }

                let minY = -scrollView.adjustedContentInset.top
                let maxY = max(
                    minY,
                    scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
                )
                targetOffset.y = min(max(targetOffset.y, minY), maxY)
                scrollView.setContentOffset(targetOffset, animated: false)
                scrollView.layoutIfNeeded()
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
    }
#endif
