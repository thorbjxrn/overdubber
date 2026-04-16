# Overdubber — Full Rewrite Design Spec

## Context

Overdubber is a multi-track audio overdubbing app originally built in May 2019 as a first iOS project. The original is ~1,040 lines of Swift 4.2/UIKit with destructive mixing (bouncing layers into a single file). The goal is a complete rewrite as a modern, polished App Store product — a creative tool that feels like a portable tape machine crossed with a Teenage Engineering device. Minimalist, functional, deadly beautiful. Quick to start, deep when you want it.

## Core Concept

Record audio layers on top of each other (overdubbing), mix them non-destructively, and export the result. The workflow defaults to a tape-like linear flow (record → add layer → record on top) but expands into a multitrack mixer when you want control over individual layers.

## Decisions

| Decision | Choice |
|---|---|
| Audio engine | AVAudioEngine (Apple-native, zero dependencies) |
| Layer cap | 16 per project |
| Per-layer controls | Volume + mute |
| Mixing model | Non-destructive (individual layers preserved) |
| Metronome | No — play to feel, not a grid |
| Export formats | WAV (lossless) + M4A (compressed) |
| Export destinations | App library, iOS Files app, Share sheet |
| Waveforms | Yes — filled waveform per layer, real-time during recording |
| Monetization | Free with ads + one-time IAP premium |
| Visual identity | Adaptive dark/light, hardware-inspired |
| Device support | iPhone + iPad, both first-class |
| UI framework | SwiftUI |
| Architecture | MVVM with @Observable |
| Persistence | SwiftData (metadata), files on disk (audio) |
| Dependencies | AdMob only (same as Simple Habit Tracker) |

## Screens

### 1. Recorder (Home)

The primary screen. A tape-machine interface:

- Large record button (chunky, tactile, pulses while recording)
- Live waveform display during recording
- Layer count indicator
- Play/Stop for hearing all layers mixed
- "Add Layer" action after recording a take
- Button/gesture to expand into mixer view
- Export button (nav bar)
- Library access (nav bar)

This is where 90% of time is spent. One-tap to start recording.

### 2. Mixer (Expandable from Recorder)

Slides up or expands from the recorder view to reveal all layers:

- Horizontal waveform strip per layer
- Volume slider per layer (0.0–1.0)
- Mute toggle per layer
- Tap a layer to select it for re-recording
- Layer reordering (drag)
- Visual indication of currently playing position

Up to 16 layer strips, scrollable. On iPad, the extra width allows wider waveforms.

### 3. Library

Two sections:

**Projects** — In-progress work you can resume:
- Project name, date, layer count, duration
- Tap to open in recorder/mixer (continue working)
- Swipe to delete (deletes project + all layer files)

**Exports** — Finished recordings:
- File name, date, duration, format (WAV/M4A)
- Tap to play
- Swipe to delete
- Share via iOS share sheet (AirDrop, Messages, etc.)
- Also accessible via iOS Files app

### 4. Settings

- Premium status indicator
- Theme picker (grid of themed circles)
- Export format preference (WAV/M4A default)
- iCloud sync toggle (premium, future)
- Privacy policy link
- Version display
- Debug section (development only)

### 5. Paywall

- Feature comparison (free vs premium)
- Dynamic pricing from StoreKit
- Restore purchases
- Triggered when hitting layer limit or accessing premium features

### 6. Onboarding

- 2-3 page quick intro
- Shows the record → layer → mix → export flow
- Matches theme aesthetics

## Audio Architecture

### Engine Design

`AudioEngine` class owns the `AVAudioEngine` instance and manages the audio graph:

```
Input Node → [Tap: live waveform] → File Writer (AVAudioFile)

Per layer:
AVAudioPlayerNode → AVMixerNode → Output Node
                     (volume per node)
```

### Recording Flow

1. Configure `AVAudioSession` for `.playAndRecord`
2. Start all existing layer player nodes (so user hears previous layers)
3. Install tap on input node for live waveform data
4. Write input to `AVAudioFile` (CAF format, lossless)
5. On stop: remove tap, finalize file, create Layer model entry

### Playback Flow

1. Load each unmuted layer's audio file into its `AVAudioPlayerNode`
2. Set volume per node from Layer model
3. Schedule all nodes, start engine
4. Tap mixer node output for playback position / level metering

### Export Flow

1. Build `AVMutableComposition` from all unmuted layers
2. Apply volume via `AVMutableAudioMixInputParameters` per track
3. Export M4A via `AVAssetExportSession` (`AVAssetExportPresetAppleM4A`), or WAV via `AVAudioEngine` offline rendering to `AVAudioFile`
4. Save to Exports directory (Files app accessible)
5. Optionally present share sheet

### Waveform Generation

- **Live (during recording)**: Extract samples from input node tap buffer, downsample for display, push to view via Combine/async stream
- **Static (saved layers)**: Read audio file, extract peak samples at display resolution, cache the result
- **Rendering**: Custom SwiftUI `Shape` or `Canvas` view — filled waveform, color from theme

### Internal Audio Format

CAF (Core Audio Format) for all internal files — lossless, fast to read/write, Apple-native. Conversion to WAV/M4A happens only on export.

## Data Model (SwiftData)

### Project

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| name | String | User-provided on save/export |
| createdDate | Date | Auto-set |
| lastModifiedDate | Date | Updated on any change |
| duration | TimeInterval | Longest layer duration |

Relationship: one-to-many → Layer (cascade delete)

### Layer

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| sortOrder | Int | Display order in mixer |
| fileName | String | Relative path to audio file |
| volume | Float | 0.0–1.0, default 1.0 |
| isMuted | Bool | Default false |
| duration | TimeInterval | Layer length |
| createdDate | Date | Auto-set |

### File Storage

```
Documents/
├── Projects/
│   └── {projectId}/
│       └── layers/
│           ├── layer-0.caf
│           ├── layer-1.caf
│           └── ...
└── Exports/          ← Files app accessible
    ├── MySong.m4a
    └── MySong.wav
```

`UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` in Info.plist to expose Exports to Files app.

## Free vs Premium

### Free Tier

- Up to 4 layers per project
- M4A export only
- Banner ads (grace period: no ads for first 5 app opens)
- Interstitial ads on export (frequency capped)
- Default theme only

### Premium (One-Time IAP)

- Up to 16 layers per project
- WAV + M4A export
- Ad-free
- Multiple hardware-inspired color themes
- iCloud sync (future, when available)

### Upsell Trigger

When user tries to add a 5th layer, show paywall. Natural moment — they're in the creative flow and want more.

## UI Design Language

### Visual Identity

"Portable tape machine × Teenage Engineering" — hardware-inspired, tactile, purposeful.

### Color System (Adaptive)

**Dark mode**: Deep charcoal background, warm amber accents (VU meter / recording indicator feel). Controls glow subtly.

**Light mode**: Clean white background, bold saturated controls (OP-1 screen energy). High contrast, playful.

### Premium Themes

Hardware-inspired palettes:
- Default (adaptive amber/white)
- TASCAM (deep dark, red accents)
- OP-1 (bright white, primary color pops)
- SP-404 (grey/orange industrial)
- Additional themes as warranted

### Typography

- Monospace or semi-mono for readout-style elements: track numbers, timestamps, level values
- System sans-serif for labels, navigation, body text
- The "instrument readout" feeling without going full skeuomorphic

### Controls

- Chunky, high-contrast buttons — feel like pressing physical hardware
- Record button: large, rounded, unmistakable. Pulses/glows during recording
- Sliders: thick track, visible thumb — easy to grab

### Waveforms

- Filled waveform style (not outline)
- Color-coded per layer or matching theme accent
- No grid lines — the waveform tells the story
- Smooth real-time drawing during recording

### Animations

Purposeful, not decorative:
- Record button pulse while recording
- Waveform draws in real-time
- Layer slides in when added
- Mixer expand/collapse is fluid

### Haptics

- Light impact: record start/stop
- Medium impact: add layer
- Success notification: export complete
- The app should feel physical in your hands

## Architecture & Code Structure

```
Overdubber/
├── OverdubberApp.swift
├── AudioEngine/
│   ├── AudioEngine.swift          # AVAudioEngine wrapper
│   ├── WaveformGenerator.swift    # Waveform data extraction
│   └── AudioExporter.swift        # Composition + export
├── Models/
│   ├── Project.swift              # SwiftData model
│   └── Layer.swift                # SwiftData model
├── ViewModels/
│   ├── RecorderViewModel.swift    # Recording state, layer management
│   ├── MixerViewModel.swift       # Volume/mute, layer ordering
│   └── LibraryViewModel.swift     # Project list, export, delete
├── Views/
│   ├── RecorderView.swift         # Main recording screen
│   ├── MixerView.swift            # Expandable multitrack view
│   ├── LibraryView.swift          # Project browser
│   ├── WaveformView.swift         # Reusable waveform renderer
│   ├── LayerRowView.swift         # Layer strip (waveform + controls)
│   ├── RecordButton.swift         # Custom tactile record button
│   ├── SettingsView.swift
│   ├── PaywallView.swift
│   └── OnboardingView.swift
├── Utilities/
│   ├── ThemeManager.swift         # Adaptive color themes
│   ├── PurchaseManager.swift      # StoreKit 2
│   └── AdManager.swift            # Google AdMob
└── Tests/
    └── OverdubberTests/
```

### Patterns

- `AudioEngine`: Plain class, not @Observable. ViewModels observe it and expose relevant state to views.
- ViewModels: `@Observable @MainActor` — same pattern as `HabitViewModel` in Simple Habit Tracker
- SwiftData `@Query` for reactive project/layer lists
- Environment-based DI for PurchaseManager, AdManager, ThemeManager
- iOS 17+ deployment target
- Swift 5.9+

## Testing Strategy

- Unit tests for AudioEngine (mock AVAudioEngine if needed, or test with bundled audio files)
- Unit tests for ViewModels (business logic, state transitions)
- Unit tests for data models (SwiftData with in-memory container)
- Unit tests for WaveformGenerator (known input → expected output)
- Manual testing via SwiftUI previews for UI iteration

## Verification Plan

1. Create a new project, record a single layer, play it back
2. Add a second layer while hearing the first — verify overdub works
3. Open mixer, adjust volume on layer 1, verify mix changes
4. Mute a layer, verify it's silent on playback
5. Export as M4A, verify file appears in library and Files app
6. Export as WAV, verify lossless output
7. Hit 4-layer limit on free tier, verify paywall appears
8. Purchase premium, verify 16 layers unlock and ads disappear
9. Test on both iPhone and iPad
10. Test dark mode and light mode
11. Verify waveforms render correctly for short and long recordings
