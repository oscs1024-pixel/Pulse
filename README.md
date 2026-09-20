# Codex Hair Bar

A native **macOS 14+** floating Codex usage monitor built with **SwiftUI + AppKit**.

Codex Hair Bar takes the screen-edge idea from Pulse and narrows it to one job: keep the Codex rate-limit windows visible without opening a dashboard.

## What it does

- Native menu-bar application with no Dock icon.
- A compact top-center “hair bar” that expands on hover.
- Reads the existing Codex login from `~/.codex/auth.json`.
- Displays the account-wide 5-hour / weekly windows returned by Codex, plus additional model-specific windows when present.
- Shows reset countdowns, plan name and optional credit balance.
- Automatic refresh every 1 / 2 / 5 / 10 minutes and manual refresh.
- Toggle between **remaining** and **used** percentages.
- Optional launch at login via `SMAppService`.
- Keeps credentials out of preferences; the existing token is only sent to the Codex/ChatGPT usage endpoint.

## Architecture

```
CodexHairBarApp
 ├─ AppDelegate (AppKit lifecycle)
 ├─ FloatingBarController (NSPanel)
 │   └─ HairBarView (SwiftUI)
 ├─ SettingsWindowController (NSWindow + SwiftUI)
 └─ UsageStore
     └─ CodexUsageService
         ├─ ~/.codex/auth.json
         └─ https://chatgpt.com/backend-api/wham/usage
```

The endpoint used by the Codex client is not a public, documented usage API and can change. The service is isolated behind `CodexUsageService` so an app-server fallback can be added without changing the UI.

## Build

Requires Xcode / Swift 6 and macOS 14+.

```bash
swift test
./Scripts/bundle.sh
open build.noindex/Codex\ Hair\ Bar.app
```

For a quick development launch:

```bash
swift run CodexHairBar
```

## Privacy

Codex Hair Bar is local-first. It reads only the existing Codex auth file needed for usage lookup. It does not copy credentials into UserDefaults and has no application backend.

## Reference

The screen-edge presentation and native macOS approach are inspired by [qunqin24/Pulse](https://github.com/qunqin24/Pulse). This branch is a separate, Codex-focused implementation rather than a rename of Pulse.

## License

Apache-2.0. See `LICENSE`.
