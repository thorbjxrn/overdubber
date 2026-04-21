# Stem Export

Export individual tracks as a zip of WAV files for mixing in external DAWs.

## Motivation

Users who create something worth polishing want to bring their tracks into Ableton Live, Logic, GarageBand, etc. Currently Overdubber only exports a single mixed-down file (M4A or WAV). Stem export gives users their individual layers as separate WAV files bundled in a zip — ready to drag into any DAW.

## Design

### ExportFormat enum

Add a `.stems` case to the existing `ExportFormat` enum:

- `rawValue`: `"Stems"`
- `fileExtension`: `"zip"`
- Conforms to existing `CaseIterable` and `Identifiable`

The segmented format picker in `ExportView` becomes: `M4A | WAV | Stems`.

### AudioExporter.exportStems

New method on `AudioExporter` that:

1. Creates a temporary directory for the individual WAV files
2. For each layer, runs the existing offline AVAudioEngine render logic (same as `exportWAV`) but with a single layer
3. Names each file `{ProjectName} - Track {N}.wav` (1-indexed)
4. Zips the temp directory into `{ProjectName} - Stems.zip` in the Exports directory
5. Cleans up the temp directory
6. Returns the zip URL

Output format per stem: 16-bit Linear PCM WAV (same settings as existing WAV export).

### Zip dependency

Add [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) via SPM. Only existing dependency is Google Mobile Ads. ZIPFoundation is lightweight, well-maintained, and produces standard zip files that any OS can open natively.

### Progress reporting

Progress is distributed across layers proportionally:

- Each layer gets an equal slice of 0.0 to 0.9 (e.g., 3 layers = each gets 0.3)
- Zip step covers 0.9 to 1.0
- Within each layer's slice, the per-frame progress from the offline render is mapped to that layer's portion

### Premium gate

Stem export is a premium-only feature:

- The `.stems` option is always visible in the format picker (so free users see it exists)
- When a non-premium user taps "Export" with Stems selected, the paywall sheet is presented instead of starting the export
- Premium users export normally with no interruption

Implementation in `ExportView`:
- Add `@Environment(PurchaseManager.self) private var purchaseManager`
- In `startExport()`, check `purchaseManager.isPremium` when `format == .stems`
- If not premium, set `showPaywall = true` and return
- Add `.sheet(isPresented: $showPaywall)` presenting `PaywallView`

### PaywallView update

Replace the current misleading "WAV Export" benefit row (WAV export is not actually gated) with the new stems feature:

- **Before:** `benefitRow(icon: "waveform", title: "WAV Export", subtitle: "Lossless audio export")`
- **After:** `benefitRow(icon: "square.stack.3d.down.right", title: "Export Stems", subtitle: "Export individual tracks for mixing in your DAW")`

## Files changed

| File | Change |
|------|--------|
| `AudioEngine/AudioExporter.swift` | Add `.stems` to `ExportFormat`, add `exportStems` method |
| `Views/ExportView.swift` | Premium gate logic, paywall sheet, pass `PurchaseManager` |
| `Views/PaywallView.swift` | Update benefit row from "WAV Export" to "Export Stems" |
| `AudioEngine/FileManagerAudio.swift` | Add `stemsTempDirectory()` helper for temp files |
| `overdubber.xcodeproj` | Add ZIPFoundation SPM dependency |

## Out of scope

- Choosing which layers to include (all layers are always exported)
- Choosing per-stem format (always WAV)
- Renaming individual stems
- Including a mixed-down file in the zip
