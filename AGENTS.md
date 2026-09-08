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

---

## 🗺️ Documentation Map

When you need specific information, consult these files in priority order:

| Question / Context | File to read |
|---|---|
| AI contract, coding rules, Xcode MCP setup (this file) | `AGENTS.md` (this file) |
| Trae workspace-rules (auto-injected into every request) | `.trae/rules/project_rules.md` |
| **Code conventions with concrete examples** — naming, UIKit + TinyConstraints, async/await, Logger, testing patterns, pre-commit checklist | `docs/conventions.md` |
| **Canonical shipped product state (v1.1.0+)** — what exists today, module boundaries, sources of truth, 1.1.x roadmap, what NOT to mix up | `docs/internal/DEV_IMPLEMENTATION_GUIDE.md` |
| **Target architecture & business logic** — domain models, service contracts, P&L formulas, tab structure, inventory rules | `docs/internal/ARCHITECTURE_AND_LOGIC.md` |
| Release sequence after v1.1.0 (1.1.x patches) | `docs/internal/ROADMAP.md` |
| Reports Hub shipped spec (P&L / ABC / Trends) | `docs/internal/REPORTS.md` |
| Solo-dev execution playbook, DoR/DoD, anti-rework rules | `docs/internal/V1_1_IMPLEMENTATION_GUIDE.md` |
| Product user flows | `docs/product/UserFlow.md` |
| Theme & color palette | `docs/engineering/ThemeColors.md` |
| Pull Request template | `.github/pull_request_template.md` |
| Project overview + deploy instructions | `README.md` |

---

## 🛠️ Xcode MCP Tools Integration

**Prerequisite for MCP:** Xcode ≥ 26.3 must be running with `TrackMyCafe.xcworkspace` open.
Enable in Xcode: `Settings → Intelligence → Model Context Protocol → [✓] Xcode Tools`.

### ✅ Priority — use these tools FIRST

| Tool | When to use |
|---|---|
| **`DocumentationSearch`** | **Always prefer this** for any Apple API question. Semantically searches Apple Docs + WWDC video transcripts. Use for UIKit, Swift Concurrency, Combine, OSLog, etc. — anything Apple-native. |
| **`BuildProject`** | Build the project after generating code. Do NOT use shell `xcodebuild` — MCP uses the same Xcode build system as the developer, with the correct scheme/target (Prod / Beta / Dev). |
| **`RunAllTests` / `RunSomeTests`** | Run tests after code changes. Prefer `RunSomeTests` with a specific test class when validating a single module. |
| **`XcodeListNavigatorIssues` + `XcodeRefreshCodeIssuesInFile`** | Use these for **live Xcode-native diagnostics** when a build fails or you suspect type issues. More authoritative than standalone LSP (they see Xcode's full compiler state). |
| **`XcodeUpdate`** | Use `str_replace`-style edits when modifying large files (e.g., big ViewControllers). Less risky than rewriting the whole file. |

### ❌ Skip / ignore — do not use

| Tool | Why skip |
|---|---|
| **`RenderPreview`** | TrackMyCafe is **UIKit-only**, no SwiftUI. Preview rendering is useless for this codebase. |
| `XcodeRead` / `XcodeGrep` / `XcodeGlob` / `XcodeLS` / `XcodeMakeDir` / `XcodeRM` / `XcodeMV` / `XcodeWrite` | Standard filesystem tools (Read, Grep, Glob, LS, Write, Edit, DeleteFile) are faster and more capable. Use Xcode file tools **only** if you explicitly need Xcode-specific project context. |
| `ExecuteSnippet` | Rarely useful in a production app context. If you need to validate logic, write a unit test instead. |
| `XcodeListWindows` | Internal plumbing for MCP tab discovery — the agent framework manages this automatically. |

### ⚠️ Important reminders for MCP

- **Targets / Schemes:** Prod (Release), Beta, Dev — the build target depends on which scheme is active in Xcode. When in doubt, ask the developer which scheme to use.
- **Realm status:** Legacy cache-layer. **Do not build new modules on Realm** (see `DEV_IMPLEMENTATION_GUIDE.md` — target v1.1.3 removes Realm from prod paths).
- **Firebase scope:** Limited to Auth, Firestore, Storage. No Functions, no Crashlytics unless explicitly requested.
- **Inventory logic:** User always enters **actual quantity**, system calculates delta automatically.
- **Dynamic Type / Layout:** Never use fixed heights for text. Multiline labels (0/2 lines), auto-shrink numeric amounts, scroll when content overflows. See `.trae/rules/project_rules.md` for the full Dynamic Type checklist.
