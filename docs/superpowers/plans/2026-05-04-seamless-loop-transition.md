# Seamless Loop Transition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hardware looper-style loop button that triggers layer transitions during recording, and record button that enters overdub during playback.

**Architecture:** Add a public `toggleLoopDuringRecording()` method to RecorderViewModel that wraps the existing private `loopToNextLayer()`. Update the loop button in RecorderView with a disabled state and contextual tap behavior. No AudioEngine changes — the existing `startRecording()` → `startOverdubRecording()` path already handles playback→recording transitions (it stops playback then rebuilds the engine graph with player nodes, which is the Approach A trade-off).

**Tech Stack:** SwiftUI, AVAudioEngine, SwiftData, @Observable

---

### Task 1: RecorderViewModel — add `toggleLoopDuringRecording()`

**Files:**
- Modify: `overdubber/ViewModels/RecorderViewModel.swift`

- [ ] **Step 1: Add `toggleLoopDuringRecording()` method**

Add after `stopRecording()` (after line 212):

```swift
func toggleLoopDuringRecording() {
    guard isRecording else { return }

    if loopingEnabled {
        loopingEnabled = false
        loopRecordDuration = nil
    } else {
        loopingEnabled = true
        if layerCount == 0 {
            guard recordingDuration >= 0.3 else { return }
            loopRecordDuration = recordingDuration
            loopToNextLayer()
        } else {
            loopRecordDuration = currentProject?.duration
        }
    }
}
```

Three branches:
- **Loop ON → OFF:** Disables loop mode and clears the auto-transition duration. Recording continues freely with no length limit.
- **Loop OFF → ON, layer 1:** Sets the loop length to however long the user has been recording, then calls `loopToNextLayer()` which stops layer 1 (saving it at the current duration), checks the layer limit, and starts recording layer 2 with the same loop duration. The 0.3s guard prevents accidental taps from creating unusably short loops.
- **Loop OFF → ON, layer 2+:** Sets `loopRecordDuration` to the project duration. The existing timer in `startDurationTimer()` will auto-transition at the next boundary (when `recordingDuration >= loopRecordDuration`). If the recording is already past the boundary, the transition fires on the next timer tick (~0.1s).

`loopToNextLayer()` is already private and handles: saving `loopRecordDuration` before `stopRecording()` clears it, checking the layer limit (calls `onLayerLimitReached` → paywall if at max), calling `startRecording()` for the next layer, and restoring `loopRecordDuration`.

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -project overdubber.xcodeproj -scheme overdubber -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add overdubber/ViewModels/RecorderViewModel.swift
git commit -m "feat: add toggleLoopDuringRecording to RecorderViewModel"
```

---

### Task 2: RecorderView — loop button disabled state and contextual behavior

**Files:**
- Modify: `overdubber/Views/RecorderView.swift`

- [ ] **Step 1: Update loop button**

Replace the loop button block (lines 196-221) with:

```swift
Button {
    guard let vm = viewModel else { return }
    withAnimation(.easeOut(duration: 0.15)) {
        if vm.isRecording {
            vm.toggleLoopDuringRecording()
        } else {
            vm.loopingEnabled.toggle()
        }
    }
} label: {
    Image(systemName: "repeat")
        .font(.title3)
        .foregroundStyle(viewModel?.loopingEnabled == true ? theme.current.accent : .secondary)
        .frame(width: 44, height: 44)
        .background(
            viewModel?.loopingEnabled == true
                ? AnyShapeStyle(theme.current.accent.opacity(0.15))
                : AnyShapeStyle(.ultraThinMaterial),
            in: Circle()
        )
        .overlay(
            Circle().strokeBorder(
                viewModel?.loopingEnabled == true
                    ? theme.current.accent.opacity(0.4)
                    : .primary.opacity(0.08),
                lineWidth: viewModel?.loopingEnabled == true ? 1.0 : 0.5
            )
        )
}
.disabled(viewModel?.isRecording != true && viewModel?.layerCount == 0)
.accessibilityLabel(viewModel?.loopingEnabled == true ? "Disable loop" : "Enable loop")
```

Changes from the original:
- **Tap handler:** During recording, calls `vm.toggleLoopDuringRecording()`. During playback or idle, toggles `loopingEnabled` directly (existing behavior).
- **Disabled state:** Disabled when not recording AND no layers exist. SwiftUI automatically dims the button visual. Enabled during recording (any layer) or when layers exist (playback loop toggle).
- **Label and styling:** Unchanged — the visual appearance (accent color when active, secondary when inactive, background highlight) stays the same.

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -project overdubber.xcodeproj -scheme overdubber -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add overdubber/Views/RecorderView.swift
git commit -m "feat: contextual loop button with disabled state"
```

---

### Task 3: Manual testing

No automated test target exists. Test on simulator or device.

- [ ] **Step 1: Loop button disabled state**
- Launch app fresh (no project)
- Verify loop button is dimmed and non-interactive
- Tap record to start layer 1 → verify loop button becomes enabled and tappable

- [ ] **Step 2: Loop activation during layer 1 recording**
- Start recording layer 1
- Wait ~3 seconds, then tap loop button
- Verify: loop icon activates, layer 1 stops, layer 2 recording starts immediately with backing playback
- Let layer 2 record → verify auto-transition to layer 3 at the ~3-second boundary
- Tap record to stop

- [ ] **Step 3: Loop deactivation during recording**
- Start a new project, record layer 1, tap loop to transition to layer 2
- While recording layer 2 (loop active), tap loop button
- Verify: loop icon deactivates, recording continues past the boundary without transitioning
- Tap record to stop

- [ ] **Step 4: Loop activation during layer 2+ recording**
- Record layer 1 (~5 seconds), stop
- Start recording layer 2 (loop off)
- After ~2 seconds, tap loop button
- Verify: loop icon activates, recording continues and auto-transitions to layer 3 at the ~5-second boundary (project duration)

- [ ] **Step 5: Record during non-looped playback**
- Record a few layers, stop
- Tap play to start playback (loop off)
- Tap record during playback
- Verify: overdub recording starts with backing layers playing

- [ ] **Step 6: Record during looped playback**
- Enable loop (tap loop icon during idle), start playback
- Tap record
- Verify: overdub recording starts, auto-transitions at loop boundaries

- [ ] **Step 7: Layer limit**
- On free tier, record layers up to the 8-layer limit
- Attempt to trigger loop transition
- Verify: paywall appears instead of starting a new layer

- [ ] **Step 8: Commit test results**

If any issues found during testing, fix and commit. Otherwise:

```bash
git log --oneline -5
```

Verify the feature branch has the two implementation commits.
