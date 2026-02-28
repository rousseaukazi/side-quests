# Side Quests

A Spotlight-style macOS menu bar launcher that posts ideas to a Discord channel with a single hotkey.

## How it works

1. Press **⌘⇧Space** anywhere — a floating panel appears, centred on screen.
2. Type your side-quest idea and hit **Enter** → the message is posted to your Discord webhook and the panel disappears.
3. Press **Escape** (or click outside the panel) to dismiss without posting.

The app lives in the menu bar (no Dock icon). Left-click the ⚡ icon to toggle the panel; right-click for a context menu with Quit.

---

## Prerequisites

| Tool | Version |
|------|---------|
| macOS | 13.0 Ventura or later |
| Xcode | 15.0 or later |
| Swift | 5.9 or later |

---

## Local setup

### 1 — Create a Discord webhook

1. Open Discord → **Server Settings** → **Integrations** → **Webhooks**.
2. Click **New Webhook**, choose a channel, copy the URL.

### 2 — Configure the webhook URL

**Option A — Build setting (recommended)**

Pass the URL at build time so it is baked into the app bundle:

```bash
xcodebuild \
  -project SideQuests.xcodeproj \
  -scheme SideQuests \
  -configuration Debug \
  DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/URL" \
  build
```

**Option B — Environment variable (dev/testing)**

If `DISCORD_WEBHOOK_URL` is not found in `Info.plist`, `Config.swift` falls back to the process environment:

```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/URL"
# Then build and run from Xcode or xcodebuild
```

### 3 — Open and build in Xcode

```bash
open SideQuests.xcodeproj
# Xcode will automatically resolve the KeyboardShortcuts SPM package.
# Press ⌘R to run.
```

### 4 — Grant Accessibility permission

On first launch, macOS will ask for **Accessibility** access (required for the global hotkey). Go to:

> System Settings → Privacy & Security → Accessibility → enable **Side Quests**

---

## GitHub Actions CI / CD

### Setup

1. Push this repository to GitHub.
2. Add your Discord webhook URL as a repository secret:
   - **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `DISCORD_WEBHOOK_URL`
   - Value: `https://discord.com/api/webhooks/...`

### What the workflow does

| Step | Action |
|------|--------|
| Trigger | Push to `main` or manual `workflow_dispatch` |
| Runner | `macos-latest` |
| Build | `xcodebuild archive` (unsigned, Release config) |
| Artifact | `SideQuests.zip` uploaded for every run (30-day retention) |
| Release | GitHub Release created automatically on every push to `main` |

The build injects `DISCORD_WEBHOOK_URL` from the secret so it is baked into `Info.plist` of the resulting `.app`.

### Download & install a CI build

1. Download `SideQuests.zip` from the GitHub Release or the Actions artifact.
2. Unzip and move `Side Quests.app` to `/Applications`.
3. Bypass Gatekeeper (unsigned build):

```bash
xattr -cr "/Applications/Side Quests.app"
open "/Applications/Side Quests.app"
```

---

## File structure

```
SideQuests/
├── SideQuests.xcodeproj/
│   └── project.pbxproj           ← Xcode project (SPM dep wired up)
├── SideQuests/
│   ├── SideQuestsApp.swift       ← @main SwiftUI App entry point
│   ├── AppDelegate.swift         ← Menu bar, global hotkey, panel lifecycle
│   ├── FloatingPanel.swift       ← NSPanel subclass (blur, sizing, monitors)
│   ├── SearchBarView.swift       ← SwiftUI text field UI
│   ├── DiscordService.swift      ← URLSession POST to webhook
│   ├── Config.swift              ← Webhook URL resolution
│   └── Info.plist                ← LSUIElement=YES, ATS, webhook key
└── .github/
    └── workflows/
        └── build.yml             ← CI: archive → zip → artifact + release
```

---

## Customisation

| What | Where |
|------|-------|
| Change hotkey | `AppDelegate.swift` → `KeyboardShortcuts.Name.togglePanel` default |
| Change panel size / position | `FloatingPanel.swift` → `panelWidth`, `panelHeight`, `centerOnActiveScreen()` |
| Change Discord username | `DiscordService.swift` → `"username"` key in payload |
| Change blur material | `FloatingPanel.swift` → `blur.material` (e.g. `.hudWindow`, `.sidebar`, `.menu`) |

---

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus — global hotkey registration (via Swift Package Manager, resolved automatically by Xcode).

---

## License

MIT — do whatever you want with it.
