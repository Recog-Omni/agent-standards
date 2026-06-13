# KMP Stack Contract — Recog-Omni

Rules for all Kotlin Multiplatform projects, applying **in addition to** `.context/06-agent-behavior.md`. Where the two overlap, this file is the more specific rule.

> Synced from [Recog-Omni/agent-standards](https://github.com/Recog-Omni/agent-standards) (`shared/stacks/kmp.md`) — edit it there, not here. Project-specific module names, commands, and library choices live in the project's `AGENTS.md` and other `.context/` files.

---

## Verification — every target, every time

A change is not done until **all targets compile** (Android, iOS, and any web target the project ships). The exact Gradle commands are in the project's `AGENTS.md` — run them all before any PR. A change that compiles on Android but breaks iOS is not done.

---

## Shared-first architecture

- Business logic belongs in `commonMain`. Platform code goes in `androidMain` / `iosMain` only when required by a platform API.
- New platform capabilities use the `expect`/`actual` pattern.
- **Never use `Dispatchers.IO` in `commonMain`** — use `Dispatchers.Default`. `Dispatchers.IO` is unavailable on Kotlin/Native iOS targets; code using it compiles on Android and fails on iOS.

---

## Tests

- Test pure logic in `commonTest` using in-memory fakes (e.g. a fake preferences store or repository) — no platform dependencies in shared tests.

---

## Persistence

- If the project uses SQLDelight: schema changes **always** require a new numbered `.sqm` migration file alongside the `.sq` schema. Never edit the schema in place.

---

## Kotlin/Native gotchas

- **JVM APIs don't exist in `iosMain`.** `System.getenv`, `System.currentTimeMillis`, `java.*` — none are available on Kotlin/Native. Use POSIX (`platform.posix.getenv(...)?.toKString()`) or `kotlin.time`/`kotlinx-datetime` equivalents.
- **UIKit `NS_ENUM` types keep the full ObjC name** — no prefix stripping.
  Correct: `UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera`
  Wrong: `UIImagePickerControllerSourceType.Camera`
- **`CValue<T>` struct fields require `.useContents {}`** for access (e.g. `CValue<CGRect>`).
- **CocoaPods interop** imports use the `cocoapods.<PodName>` package namespace (set via `packageName` in the pod block), not the pod's framework name.

---

## No regressions

- Changing shared code (navigation, repository/data layer, the app entry composable) requires checking every screen and platform entry point it affects — on both platforms.
