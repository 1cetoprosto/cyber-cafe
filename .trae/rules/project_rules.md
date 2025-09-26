# Project Rules for TrackMyCafe (Cyber Cafe)

These rules must be followed by AI when generating or editing code.

---

## 📌 Project Context

- **Platform:** iOS 15+ (Universal: iPhone + iPad)
- **Deployment Target:** iPhone + iPad (Universal app)
- **Language:** Swift 5.x
- **UI Framework:** UIKit (programmatic UI, no Storyboard/XIB)
- **Architecture:** MVVM
- **Databases:** Firebase Firestore + Realm
- **Auth:** Firebase Auth + Biometric (FaceID/TouchID)
- **Other Services:** Firebase Storage, KeychainAccess
- **Dependencies:** Firebase SDK ≥ 10.x, Realm ≥ 10.x

---

## 🛠 Coding Conventions

1. **Follow Apple Swift API Design Guidelines.**
2. **UIKit only** — do not use SwiftUI or SwiftUI DSL syntax.
3. **File structure:** respect existing folders (`Application`, `Data Layer`, `Services`, `View Layer`).
4. **MVVM pattern strictly:**
   - Models → `Data Layer/Models`
   - ViewModels → `View Layer/Flow/*/ViewModel`
   - Views → `View Layer/Flow`
5. **Avoid `!` force‑unwraps and global state.**
6. **Asynchronous code:**
   - Keep completion handlers in existing modules.
   - Prefer async/await for **new code** (Firebase SDK ≥ 10 async/await API only).
   - No old completion closures in new code.
7. **Use protocols for abstraction and Dependency Injection.**
8. **Classes = Single Responsibility only.**
9. **File size limit:** If class > 300 lines — split into multiple files following single responsibility principle.
10. **Naming conventions:** PascalCase for classes, camelCase for methods, snake_case forbidden.
11. **Layer separation:**
    - UIKit imports only in View Layer (controllers/views)
    - ViewModels must not import UIKit
    - Models must be UI-framework agnostic

---

## 🔒 Security & Architecture Rules

1. **Dependency Injection:** ViewModels receive services (Firestore, Auth) through protocols/initializers, not direct calls (`Firestore.firestore()`).
2. **Keychain Access:** Use KeychainAccess library only. Do not create custom Keychain wrappers.
3. **Logging:** No `print()` statements in production code. Use `Logger`/`OSLog` only.
4. **Firebase limitations:** Auth, Firestore, Storage only. No other Firebase services without explicit approval.

---

## 🤖 AI Rules

- **Do not invent APIs/libraries.**
- **Always generate compilable Swift code with proper `import` statements.**
- **Code must be self‑contained, ready to paste into the project.**
- **Comments and commit messages: English only.**
- **Explanations (responses outside code): Ukrainian only.**
- **Response size limit:** If implementation > 300 lines, split into multiple files or ask for confirmation.
- **Show diff first:** Before modifying existing files, show expected changes as diff.
- **Validation step:** After code changes, describe Expected Build Outcome (e.g., "app still compiles, login flow still works").

---

## 📖 Output Format

- **Always return code in ```swift fenced blocks.**
- **Short explanation in Ukrainian after code block (not inside code).**
- **Plan → Action → Validation approach:**
  1. Brief plan of changes
  2. Code implementation
  3. Expected outcome description

---

## ✅ Good vs Bad Examples

❌ **Bad (not allowed):**

```swift
Text("Hello World") // SwiftUI
let db = Firestore.firestore() // Direct service access in ViewModel
print("Debug info") // Print in production code
```

✅ **Good (allowed):**

```swift
import UIKit

protocol FirestoreServiceProtocol {
    func fetchOrders() async throws -> [Order]
}

final class OrdersViewController: UIViewController {
    private let viewModel: OrdersViewModelProtocol

    init(viewModel: OrdersViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Orders"
        setupUI()
    }
}
```

---

## 🔑 Commit Rules

- **Language:** English only
- **Format:** `type(scope): message`
- **Allowed types:** `feat`, `fix`, `refactor`, `chore`, `docs`

**Examples:**
```
feat(orders): add OrderListViewModel with async/await
fix(auth): correct Firebase login error handling
refactor(models): extract Order validation logic
```

---

## 🚫 Critical Limitations & Protections

### File System Protection

- **Never modify `project.pbxproj` manually** — only through Xcode toolchain
- **Never modify `Info.plist` directly** — only through PropertyList API or Xcode Settings
- **No manual changes to build configurations**

### Code Restrictions

- **No third‑party databases** (CoreData, SQLite, etc.)
- **No deprecated APIs** unless migration is impossible
- **No SwiftUI replacements for UIKit**
- **No experimental frameworks** unless explicitly requested
- **No new SPM dependencies** without user confirmation
- **No Combine framework** — stick to async/await and completion handlers

### Architecture Enforcement

- **Models must not contain UI logic**
- **ViewModels must not import UIKit**
- **Views must not contain business logic**
- **Services must be protocol-based for testability**

---

## 🎯 Expected AI Behavior

1. **Before any file modification:** Show diff of proposed changes
2. **After implementation:** Describe what should work/compile
3. **For large changes:** Break into smaller, reviewable chunks
4. **For architecture questions:** Always suggest MVVM-compliant solution
5. **For Firebase integration:** Always use latest async/await APIs
6. **For UI implementation:** Always use programmatic UIKit approach

---

## 📱 Platform-Specific Considerations

- **Universal app:** Code must work on both iPhone and iPad
- **Responsive design:** Use Auto Layout for different screen sizes
- **iPad-specific:** Consider split view, multitasking, larger screens
- **Accessibility:** Follow iOS accessibility guidelines
- **Performance:** Consider memory usage on older devices (iOS 15+ support)
