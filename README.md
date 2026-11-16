# Checklist (iOS 18)

A minimal SwiftUI + SwiftData checklist app.

- **To Do tab** — type an item and press Return (or tap +). Tap the circle (or swipe right) to complete it. Swipe left to delete.
- **Archive tab** — completed items with their creation and completion date/time, newest first. Swipe right to restore, swipe left to delete.

Data is saved on the device automatically (SwiftData).

## Files

| File | Purpose |
|---|---|
| `Checklist/ChecklistApp.swift` | App entry point, sets up storage |
| `Checklist/TodoItem.swift` | Data model (title, createdAt, completedAt) |
| `Checklist/ContentView.swift` | Tab bar + date formatting helper |
| `Checklist/TodoListView.swift` | Active items screen |
| `Checklist/ArchiveView.swift` | Archived items screen |

## Build without a Mac (GitHub Actions)

Every push to `main` runs [.github/workflows/build.yml](.github/workflows/build.yml) on a GitHub-hosted macOS machine. It:

1. generates the Xcode project from [project.yml](project.yml) with XcodeGen,
2. builds `Checklist-unsigned.ipa` (for a real iPhone),
3. builds `Checklist-simulator.app.zip` (for an iOS simulator),
4. launches the app in a simulator and saves `screenshot.png`,
5. attaches all of these to the **Latest build** release on the repo's Releases page.

**Try it in a browser from Windows:** upload `Checklist-simulator.app.zip` to [appetize.io](https://appetize.io) (free tier). It runs the app in an iOS simulator in your browser.

**Install it on your iPhone from Windows:** the `.ipa` is unsigned. Use [Sideloadly](https://sideloadly.io) with your Apple ID to sign and install it. With a free Apple ID you have to re-install it every 7 days.

## Build it on a Mac (Xcode 16 or newer)

1. Open Xcode → **File → New → Project… → iOS → App**.
2. Product Name: `Checklist`, Interface: **SwiftUI**, Language: **Swift**, Storage: **None**.
3. In the new project, delete the generated `ContentView.swift` and `ChecklistApp.swift` (Move to Trash).
4. Drag the five `.swift` files from this repo's `Checklist/` folder into the project navigator (tick **Copy items if needed** and the app target).
5. Select the project → target **Checklist** → **General** → set **Minimum Deployments** to **iOS 18.0**.
6. Pick a simulator or your iPhone and press **⌘R**.

To run on your own iPhone, sign in with your Apple ID under **Signing & Capabilities** (a free account works; the app then needs re-installing every 7 days).
