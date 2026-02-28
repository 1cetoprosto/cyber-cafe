# TrackMyCafe (iOS/Swift)
- Platform: iOS 15+, Universal.
- UI: UIKit ONLY (Programmatic, TinyConstraints). NO SwiftUI/Storyboard.
- Architecture: Strict MVVM. ViewModels: NO UIKit imports, use Protocols for DI.
- Stack: Firebase v10+ (Auth, Firestore, Storage), Realm v10+, KeychainAccess.
- Async: Use async/await only. No force-unwraps (!).
- Logging: OSLog/Logger only. No print().
- Files: No manual .pbxproj/Info.plist edits.
- Commits: English, Conventional (feat/fix/refactor).
- PRs: Use .github/pull_request_template.md.
