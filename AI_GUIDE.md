# AI Guide for TrackMyCafe

This file defines the rules AI assistants must follow when generating or editing code for the **TrackMyCafe** iOS application.  
It should be treated as a contract between developers and AI.

---

## 📌 Project Context

- **Platform:** iOS 15+
- **Language:** Swift 5.x
- **UI Framework:** UIKit (programmatic UI only, no Storyboard/XIB)
- **Architecture:** MVVM
- **Databases:** Firebase Firestore + Realm
- **Authentication:** Firebase Auth + Biometric (FaceID/TouchID)
- **Other Services:** Firebase Storage, KeychainAccess
- **Dependency Management:** CocoaPods + Swift Package Manager
- **Localization:** English and Ukrainian (via R.swift)

---

## 🛠 Coding Rules

1. Follow **Apple Swift API Design Guidelines**.
2. UIKit is the primary UI framework. **Do not replace UIKit with SwiftUI.**
3. Organize new modules inside the existing folder structure (`Application`, `Data Layer`, `Services`, `View Layer`).
4. Apply **MVVM pattern**:
   - Models in `Data Layer/Models`
   - ViewModels in `View Layer/Flow/*/ViewModel`
   - Views (UIViewControllers) in `View Layer/Flow`
5. Avoid **force-unwrapping (`!`)** and global state.
6. Asynchronous code:
   - Keep existing **completion handlers**
   - **Prefer async/await for new code when possible.**
7. Use **protocols** for abstraction and testability.
8. Keep classes focused on **Single Responsibility Principle**.

---

## 🤖 AI Rules

- **Never invent APIs or libraries.**
- **Always generate compiling Swift code**, including `import` statements.
- Provide **full self-contained examples** ready to paste into the codebase.
- Use **English** for:
  - Commit messages
  - Code comments
- Explanations provided to developers (outside of code) may be in Ukrainian.
- Firebase usage is **restricted** to:
  - `Firebase Auth`
  - `Firestore`
  - `Firebase Storage`

---

## 🧩 Response Format

- Code must always be inside fenced blocks:

```swift
import UIKit

final class ExampleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
```