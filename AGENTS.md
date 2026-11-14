# AI Guide for TrackMyCafe

This file defines the rules AI assistants must follow when generating or editing code for the **TrackMyCafe** iOS application.
It should be treated as a contract between developers and AI.

---

## 📌 Project Context

- **Platform:** iOS 15+
- **Language:** Swift 5.x
- **UI Framework:** UIKit (programmatic UI only, no Storyboard/XIB)
- **Architecture:** MVVM
- **Databases:** Firebase Firestore
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
| AI contract, coding rules, dual-stack tooling (this file) | `AGENTS.md` (this file) |
| Dual-stack always-apply rule (`xcode-tools` vs MobileBuildMCP) | `.cursor/rules/trackmycafe-xcode-tooling.mdc` |
| Trae workspace-rules (auto-injected into every request) | `.trae/rules/project_rules.md` |
| **Code conventions with concrete examples** — naming, UIKit + TinyConstraints, async/await, Logger, testing patterns, pre-commit checklist | `docs/conventions.md` |
| **Canonical shipped product state (v1.1.0+)** — what exists today, module boundaries, sources of truth, 1.1.x roadmap, what NOT to mix up | `docs/internal/DEV_IMPLEMENTATION_GUIDE.md` |
| **Target architecture & business logic** — domain models, service contracts, P&L formulas, tab structure, inventory rules | `docs/internal/ARCHITECTURE_AND_LOGIC.md` |
| Release sequence after v1.1.0 (1.1.x patches) | `docs/internal/ROADMAP.md` |
| Reports Hub shipped spec (P&L / ABC / Trends) | `docs/internal/REPORTS.md` |
| Solo-dev execution playbook, DoR/DoD, anti-rework rules | `docs/internal/V1_1_IMPLEMENTATION_GUIDE.md` |
| Product user flows | `docs/product/UserFlow.md` |
| **External positioning & copy pack** (onboarding, paywall) + GTM next steps | `docs/product/POSITIONING_AND_COPY.md` |
| **App Store Connect listing** (description, keywords, live screenshots status) | `docs/product/app-store/LISTING.md` (+ `docs/product/app-store/README.md`) |
| Theme & color palette | `docs/engineering/ThemeColors.md` |
| Pull Request template | `.github/pull_request_template.md` |
| Project overview + deploy instructions | `README.md` |

---

## 🛠️ Build tooling (dual-stack)

Це **два способи керувати проєктом**, не два конкуруючі білдери. Деталі — у `.cursor/rules/trackmycafe-xcode-tooling.mdc`.

- **`xcode-tools`** — міст у відкритий Xcode (`TrackMyCafe.xcodeproj`, SPM; без `.xcworkspace`). Xcode ≥ 26.3, MCP Xcode Tools увімкнені.
- **MobileBuildMCP** — headless sim build/run/test / UI automation без відкритого Xcode (скіл `mobilebuildmcp`, дефолти `.mobilebuildmcp/config.yaml`).

Правило: Xcode уже з TrackMyCafe → `xcode-tools`; sim/UI без IDE → MobileBuildMCP. Не дублюй збірку обома. Не shell `xcodebuild`, якщо є MCP.

| Потрібно | Береш |
|---|---|
| Compile у відкритому Xcode | `BuildProject` |
| Логіка | `RunSomeTests` (не `ExecuteSnippet`) |
| Sim + app + taps / скрін | MobileBuildMCP |
| Xcode закритий | MobileBuildMCP |
| Apple API / WWDC | `DocumentationSearch` |
| Firebase / сторонні SDK | Context7 |

### ✅ Priority — xcode-tools FIRST when Xcode is open

| Tool | When to use |
|---|---|
| **`DocumentationSearch`** | Apple-native APIs (UIKit, Concurrency, Combine, OSLog…). |
| **`BuildProject`** | After code changes. Same Xcode build system as the developer (`TrackMyCafe Prod` / `Beta` / `Dev`). |
| **`RunAllTests` / `RunSomeTests`** | Prefer `RunSomeTests` for a single module. |
| **`XcodeListNavigatorIssues` + `XcodeRefreshCodeIssuesInFile`** | Live Xcode diagnostics after build failures. |
| **`XcodeUpdate`** | `str_replace`-style edits on large ViewControllers. |

### ❌ Skip / ignore — do not use

| Tool | Why skip |
|---|---|
| **`RenderPreview`** | **UIKit-only** — no SwiftUI previews. |
| `XcodeRead` / `XcodeGrep` / `XcodeGlob` / `XcodeLS` / `XcodeMakeDir` / `XcodeRM` / `XcodeMV` / `XcodeWrite` | Prefer standard FS tools unless you need IDE project context. |
| `ExecuteSnippet` | Prefer a unit test. |
| `XcodeListWindows` | Tab discovery plumbing — use only when multiple Xcode windows are open. |

### ⚠️ Important reminders

- **Targets / Schemes:** `TrackMyCafe Prod`, `TrackMyCafe Beta`, `TrackMyCafe Dev` — ask when in doubt.
- **Firebase scope:** Auth, Firestore, Storage only (no Functions / Crashlytics unless requested).
- **Inventory logic:** User enters **actual quantity**; system calculates delta.
- **Dynamic Type / Layout:** No fixed heights for text. See `.trae/rules/project_rules.md`.
