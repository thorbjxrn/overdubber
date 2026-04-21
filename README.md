# Overdubber

A multi-track audio layering app for iOS. Record a take, then overdub as many layers as you want — like a portable tape machine.

appstore: https://apps.apple.com/us/app/overdubber/id6762368689
demo: https://youtu.be/U47ZLFZjnVQ

## Features

- **Layer-based recording** — Record your first take, then overdub on top with live playback of previous layers
- **Mixer** — Per-layer volume controls and mute toggles
- **Loop recording** — Automatically loop at the project duration for hands-free overdubbing
- **Tape warmth** — Optional analog saturation effect applied during recording
- **Input monitoring** — Hear yourself through headphones while recording
- **Waveform display** — Visual waveforms for each layer and live input
- **Export** — Mix down to M4A or WAV and share
- **Themes** — Standard, Portastudio, Synth, and Sampler color schemes
- **Project library** — Save, rename, and manage multiple projects

## Requirements

- iOS 17.0+
- Xcode 16+
- Microphone access

## Architecture

SwiftUI + MVVM, backed by SwiftData for project/layer persistence and AVAudioEngine for all audio.

```
overdubber/
├── Models/              # SwiftData models (Project, Layer)
├── ViewModels/          # RecorderViewModel
├── Views/               # SwiftUI views
├── AudioEngine/         # AVAudioEngine, export, waveform generation
└── Utilities/           # Theme, purchases, ads
```

## Building

Open `overdubber.xcodeproj` in Xcode and run on a physical device (microphone required).

## License

All rights reserved.
