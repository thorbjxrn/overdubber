# Stem Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Export individual tracks as a zip of WAV files for mixing in external DAWs.

**Architecture:** Add `.stems` to `ExportFormat`, implement per-layer WAV rendering in `AudioExporter`, zip results with ZIPFoundation, gate behind premium in `ExportView`, and update PaywallView upsell copy.

**Tech Stack:** Swift, AVFoundation (offline rendering), ZIPFoundation (SPM), SwiftUI

---

### Task 1: Add ZIPFoundation SPM dependency

**Files:**
- Modify: `overdubber.xcodeproj/project.pbxproj`

This must be done in Xcode since SPM dependency changes require Xcode project integration.

- [ ] **Step 1: Add ZIPFoundation package via Xcode**

Open the project in Xcode. Go to the project (not target) settings > Package Dependencies > tap `+`. Enter the URL:

```
https://github.com/weichsel/ZIPFoundation
```

Use "Up to Next Major Version" from `0.9.0`. Add the `ZIPFoundation` library to the `overdubber` target.

- [ ] **Step 2: Verify it resolves**

Build the project (Cmd+B). Xcode will fetch the package and update `Package.resolved`. Verify the build succeeds.

- [ ] **Step 3: Verify import works**

Temporarily add `import ZIPFoundation` to `AudioExporter.swift`, build, then remove it. This confirms the linkage is correct.

- [ ] **Step 4: Commit**

```bash
git add overdubber.xcodeproj/project.pbxproj overdubber.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "Add ZIPFoundation SPM dependency for stem export"
```

---

### Task 2: Add `.stems` case to `ExportFormat` and `stemsTempDirectory` to `FileManagerAudio`

**Files:**
- Modify: `overdubber/AudioEngine/AudioExporter.swift:1-15`
- Modify: `overdubber/AudioEngine/FileManagerAudio.swift`

- [ ] **Step 1: Add `.stems` case to `ExportFormat`**

In `AudioExporter.swift`, update the `ExportFormat` enum to:

```swift
enum ExportFormat: String, CaseIterable, Identifiable {
    case m4a = "M4A"
    case wav = "WAV"
    case stems = "Stems"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .m4a: "m4a"
        case .wav: "wav"
        case .stems: "zip"
        }
    }
}
```

- [ ] **Step 2: Add `stemsTempDirectory` to `FileManagerAudio.swift`**

Add this method to the `FileManager` extension in `FileManagerAudio.swift`:

```swift
static func stemsTempDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("StemExport", isDirectory: true)
    try? FileManager.default.removeItem(at: url)
    ensureDirectoryExists(at: url)
    return url
}
```

- [ ] **Step 3: Build and verify**

Run: Cmd+B in Xcode. The build should succeed. The `.stems` case isn't handled in `export()` yet — that's fine, the compiler will warn but not error since there's no exhaustive switch yet. Actually, the `export()` method's switch on `format` will produce a compiler error for the missing case. Add a temporary placeholder to keep it building:

In the `export()` method's switch statement, add:

```swift
case .stems:
    throw ExportError.exportFailed("Not yet implemented")
```

- [ ] **Step 4: Commit**

```bash
git add overdubber/AudioEngine/AudioExporter.swift overdubber/AudioEngine/FileManagerAudio.swift
git commit -m "Add .stems export format case and temp directory helper"
```

---

### Task 3: Implement `exportStems` in `AudioExporter`

**Files:**
- Modify: `overdubber/AudioEngine/AudioExporter.swift`

- [ ] **Step 1: Add the `import ZIPFoundation` statement**

At the top of `AudioExporter.swift`, add:

```swift
import ZIPFoundation
```

- [ ] **Step 2: Replace the `.stems` placeholder in `export()`**

Replace the temporary `.stems` case in the `export()` method's switch with:

```swift
case .stems:
    try await exportStems(layers: layers, name: name, onProgress: onProgress)
```

Also update the `outputURL` and `removeItem` logic. The current code builds `outputURL` before the switch and removes any existing file. For stems, the output path is different (zip). Restructure `export()` to:

```swift
func export(
    layers: [(url: URL, volume: Float)],
    format: ExportFormat,
    name: String,
    onProgress: @Sendable @escaping (Double) -> Void
) async throws -> URL {
    guard !layers.isEmpty else { throw ExportError.noLayers }

    let outputURL = FileManager.exportsDirectory()
        .appendingPathComponent("\(name).\(format.fileExtension)")

    try? Foundation.FileManager.default.removeItem(at: outputURL)

    switch format {
    case .wav:
        try await exportWAV(layers: layers, to: outputURL, onProgress: onProgress)
    case .m4a:
        try await exportM4A(layers: layers, to: outputURL, onProgress: onProgress)
    case .stems:
        try await exportStems(layers: layers, to: outputURL, name: name, onProgress: onProgress)
    }

    return outputURL
}
```

- [ ] **Step 3: Implement `exportStems`**

Add this method to `AudioExporter`, after the existing `exportM4A` method:

```swift
// MARK: - Stems (individual WAVs → ZIP)

private func exportStems(
    layers: [(url: URL, volume: Float)],
    to outputURL: URL,
    name: String,
    onProgress: @Sendable @escaping (Double) -> Void
) async throws {
    let tempDir = FileManager.stemsTempDirectory()
    let layerCount = layers.count
    let progressPerLayer = 0.9 / Double(layerCount)

    defer {
        try? Foundation.FileManager.default.removeItem(at: tempDir)
    }

    for (index, layer) in layers.enumerated() {
        let stemName = "\(name) - Track \(index + 1)"
        let stemURL = tempDir.appendingPathComponent("\(stemName).wav")

        try await exportWAV(
            layers: [(url: layer.url, volume: layer.volume)],
            to: stemURL,
            onProgress: { layerProgress in
                let base = Double(index) * progressPerLayer
                onProgress(base + layerProgress * progressPerLayer)
            }
        )
    }

    onProgress(0.9)

    try Foundation.FileManager.default.zipItem(at: tempDir, to: outputURL)

    onProgress(1.0)
}
```

- [ ] **Step 4: Build and verify**

Run: Cmd+B in Xcode. Build should succeed with no errors.

- [ ] **Step 5: Commit**

```bash
git add overdubber/AudioEngine/AudioExporter.swift
git commit -m "Implement stem export with per-layer WAV rendering and zip bundling"
```

---

### Task 4: Add premium gate and stems UI to `ExportView`

**Files:**
- Modify: `overdubber/Views/ExportView.swift`

- [ ] **Step 1: Add `PurchaseManager` environment and paywall state**

Add these properties to `ExportView` alongside the existing `@Environment` and `@State` declarations:

```swift
@Environment(PurchaseManager.self) private var purchaseManager
@State private var showPaywall = false
```

- [ ] **Step 2: Add the paywall sheet modifier**

Add this modifier to the `NavigationStack`, after the existing `.toolbar { }` modifier:

```swift
.sheet(isPresented: $showPaywall) {
    PaywallView(purchaseManager: purchaseManager)
}
```

- [ ] **Step 3: Add premium check in `startExport()`**

At the top of `startExport()`, before the `isExporting = true` line, add:

```swift
if format == .stems && !purchaseManager.isPremium {
    showPaywall = true
    return
}
```

- [ ] **Step 4: Build and verify**

Run: Cmd+B in Xcode. Build should succeed.

- [ ] **Step 5: Commit**

```bash
git add overdubber/Views/ExportView.swift
git commit -m "Add premium gate for stem export in ExportView"
```

---

### Task 5: Update PaywallView benefit copy

**Files:**
- Modify: `overdubber/Views/PaywallView.swift:58`

- [ ] **Step 1: Replace the WAV Export benefit row**

In `PaywallView.swift`, in the `benefitsSection` computed property, change:

```swift
benefitRow(icon: "waveform", title: "WAV Export", subtitle: "Lossless audio export")
```

to:

```swift
benefitRow(icon: "square.stack.3d.down.right", title: "Export Stems", subtitle: "Export individual tracks for mixing in your DAW")
```

- [ ] **Step 2: Build and verify**

Run: Cmd+B in Xcode. Build should succeed.

- [ ] **Step 3: Commit**

```bash
git add overdubber/Views/PaywallView.swift
git commit -m "Update paywall benefit from WAV Export to Export Stems"
```

---

### Task 6: Manual testing

No automated tests — this is an audio I/O + UI feature that needs real device testing.

- [ ] **Step 1: Test stem export (premium)**

1. Enable premium via debug toggle in Settings
2. Create a project with 2-3 recorded layers
3. Tap Export, select "Stems" format
4. Tap Export button
5. Verify progress bar advances smoothly
6. Verify share sheet appears with a `.zip` file
7. Share to Files app, open the zip
8. Verify it contains one WAV per layer, named `ProjectName - Track 1.wav` etc.
9. Verify each WAV plays correctly and matches the original layer audio

- [ ] **Step 2: Test premium gate (free user)**

1. Disable premium via debug toggle
2. Open Export, select "Stems"
3. Tap Export
4. Verify the paywall sheet appears instead of exporting
5. Dismiss paywall, verify you're back on the export screen
6. Verify M4A and WAV export still work without paywall

- [ ] **Step 3: Test edge cases**

1. Export stems from a project with only 1 layer — should produce a zip with one WAV
2. Export stems from a project where layers have different durations — each WAV should match its layer's duration
3. Verify muted layers are still exported (mute affects playback, not stems — volume is applied per-layer)

- [ ] **Step 4: Verify PaywallView**

1. Open Settings > Upgrade (as free user)
2. Verify "Export Stems" appears with the correct icon and subtitle
3. Verify "WAV Export" no longer appears

- [ ] **Step 5: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "Fix issues found during stem export testing"
```

Only commit if changes were made during testing.
