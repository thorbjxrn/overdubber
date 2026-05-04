# Seamless Loop Transition

Hardware looper-style recording flow: tapping the loop button during recording sets the loop length and immediately transitions to the next layer. Tapping record during playback jumps into overdub recording without interrupting playback.

## Current Behavior

- Loop button toggles `loopingEnabled` at any time
- Recording auto-transitions to next layer at loop boundary via timer-based `loopToNextLayer()` (0.1s polling)
- Starting a new recording during playback requires stopping playback first, then tapping record

## New Behavior

### Loop Button State Matrix

| State | Loop button | Tap behavior |
|-------|------------|-------------|
| No layers, not recording | Disabled (dimmed) | Nothing |
| Recording layer 1, loop off | Enabled | Enable loop mode. Set loop length = current recording duration. Trim layer 1 at that point. Transition to layer 2 via `loopToNextLayer()` |
| Recording layer 2+, loop off | Enabled | Enable loop mode. Set `loopRecordDuration` = project duration. Current layer auto-transitions at next loop boundary |
| Recording any layer, loop on | Enabled | Disable loop mode. Clear `loopRecordDuration`. Recording continues freely with no length limit |
| Playback (not recording) | Enabled | Toggle looped playback (existing behavior, unchanged) |

### Record Button During Playback

| State | Tap behavior |
|-------|-------------|
| Playback (looped or not) | Start overdub recording immediately at current playback position. Playback continues uninterrupted. If loop mode is on, `loopRecordDuration` is set from project duration. |

### Auto-Loop (Unchanged)

The existing timer-based auto-transition at loop boundaries continues to work as-is. When recording with `loopRecordDuration` set and elapsed time reaches the duration, `loopToNextLayer()` fires automatically.

### Layer Limit

All transitions (manual and auto) check the layer limit before starting the next layer. Free tier: 8 layers. Premium: unlimited. If at limit, `onLayerLimitReached?()` fires (shows paywall). Existing checks in `loopToNextLayer()` handle this.

## Approach

Reuse the existing `loopToNextLayer()` mechanism. No audio engine architecture changes. Timer-based boundary detection (0.1s precision) is kept as-is — good enough for this version.

Future improvements (in backlog): sample-accurate transitions, gapless recording via continuous file splitting, quantized loop start.

## Files Changed

### RecorderViewModel.swift

- New public method for manual loop transition (wraps `loopToNextLayer()` with layer-1 trim logic)
- Handle "layer 1 trim" case: when loop mode is toggled on during layer 1 recording, the current elapsed duration becomes the loop length, recording stops at that point, and layer 2 starts
- Clear/set `loopRecordDuration` when loop mode is toggled during recording

### RecorderView.swift

- Loop button: disabled state when no layers and not recording
- Loop button: contextual tap handler — calls manual loop transition when `isRecording`, toggles playback loop when not recording
- Record button: when playback is active (looped or not), start overdub recording at current position without stopping playback

### AudioEngine.swift

- New method or mode to start recording while playback is already running. Currently `startOverdubRecording()` creates its own player nodes from scratch. For record-during-playback, the engine needs to install a recording tap on the input node and start writing to a new audio file without tearing down or restarting the existing player nodes. Playback continues uninterrupted.

## What Stays the Same

- Auto-loop at boundaries (existing `loopToNextLayer()` timer logic)
- Record button stops everything when tapped during recording (existing `toggleRecording()`)
- Layer limit checks
- All audio file handling (CAF format, `FileManager.layerFileURL()`)
- SwiftData models (Layer, Project)
- Waveform generation
- Tape warmth effect
- Volume/mute controls
