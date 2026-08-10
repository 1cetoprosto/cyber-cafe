# TrackMyCafe (iOS/Swift)
- Platform: iOS 15+, Universal.
- UI: UIKit ONLY (Programmatic, TinyConstraints). NO SwiftUI/Storyboard.
- Architecture: Strict MVVM. ViewModels: NO UIKit imports, use Protocols for DI.
- Stack: Firebase v10+ (Auth, Firestore, Storage), Realm v10+, KeychainAccess.
- Async: Use async/await only. No force-unwraps (!).
- Logging: OSLog/Logger only. No print().
- Reviews: Do not include diffs in assistant responses unless explicitly requested.
- Layout (Dynamic Type): Avoid fixed heights for text; allow multiline (0/2 lines) for titles/descriptions; use auto-shrink (adjustsFontSizeToFitWidth + minimumScaleFactor) for numeric amounts where wrapping is undesired; set hugging/compression priorities intentionally; prefer scroll when content can overflow on small screens or Accessibility text sizes.
- Files: No manual .pbxproj/Info.plist edits.
- Commits: English, Conventional (feat/fix/refactor).
- PRs: Use .github/pull_request_template.md.

## Onboarding (Feature Tours / Coach Marks)
- Source: `TrackMyCafe/View Layer/UI/Onboarding/OnboardingManager.swift` + `InstructionsDriver.swift`
- **Flow versionTag MUST equal the app release version when the feature first ships** (e.g. Track Ingredients toggle → 1.0.10, Dashboard → 1.1.0). This enables the core behavior:
  - Brand-new users see ALL flows (no completed keys yet → full tour).
  - Existing users upgrading from an older release see ONLY the flows with a versionTag newer than their last-seen.
  - Users never re-see a completed flow even if the app version bumps, because `OnboardingManager.startIfNeeded` checks `flow.versionTag`, NOT `CFBundleShortVersionString`.
- Checklist when adding a new onboarding for a feature (always follow):
  1. Add a new case to `OnboardingFeature` enum.
  2. Create an `OnboardingFlow` in `buildDefaultOnboardingRegistry()` with `versionTag: "<release>"` matching the planned app version. Use a unique `targetKey` per step (accessibilityIdentifier of the highlighted view).
  3. Register the flow via `OnboardingManager.shared.register(flow:)`.
  4. Set `accessibilityIdentifier = "<targetKey>"` on the target UI element in its view controller (cell, button, input, bar item). For table/collection cells, set it in `cellForRowAt` using the known index/section.
  5. Call `OnboardingManager.shared.startIfNeeded(for: .newCase, on: self)` in the host VC's `viewDidAppear(_:)`.
  6. Add matching UK/EN localization keys `onboarding<X>Title` / `onboarding<X>Message` in both `Global.strings` (uk.lproj + en.lproj).
  7. If the debug "Reset Onboarding" action exists in Settings, include the new feature in its manual `startIfNeeded` calls so QA can trigger it.
- Never change `versionTag` of an existing shipped flow (that would force all users to re-see it). If you want to refresh an old tour, create a new OnboardingFeature case instead.
- Tooltips are shown per-screen (one host VC per `startIfNeeded` call). If a new feature spans multiple screens, register multiple separate flows (one per screen) with the same release versionTag — they will all run independently when their host appears.

