import SwiftUI
import Observation

enum AppTheme: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case portastudio = "Porta"
    case synth = "Synth"
    case sampler = "Sampler"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .standard: Color(.sRGB, red: 0.85, green: 0.18, blue: 0.15)
        case .portastudio: Color(.sRGB, red: 0.8, green: 0.15, blue: 0.15)
        case .synth: Color(.sRGB, red: 0.2, green: 0.6, blue: 1.0)
        case .sampler: Color(.sRGB, red: 0.9, green: 0.5, blue: 0.1)
        }
    }

    var waveform: Color {
        switch self {
        case .standard: Color(.sRGB, red: 0.82, green: 0.2, blue: 0.17)
        case .portastudio: Color(.sRGB, red: 0.9, green: 0.2, blue: 0.2)
        case .synth: Color(.sRGB, red: 0.3, green: 0.7, blue: 1.0)
        case .sampler: Color(.sRGB, red: 1.0, green: 0.6, blue: 0.2)
        }
    }

    var record: Color {
        switch self {
        case .standard: Color(.sRGB, red: 0.82, green: 0.16, blue: 0.14)
        case .portastudio: Color(.sRGB, red: 0.85, green: 0.1, blue: 0.1)
        case .synth: Color(.sRGB, red: 1.0, green: 0.3, blue: 0.3)
        case .sampler: Color(.sRGB, red: 0.9, green: 0.3, blue: 0.1)
        }
    }

    var playhead: Color {
        switch self {
        case .standard: .primary
        case .portastudio: Color(.sRGB, red: 0.9, green: 0.85, blue: 0.7)
        case .synth: Color(.sRGB, red: 0.1, green: 0.4, blue: 0.8)
        case .sampler: Color(.sRGB, red: 1.0, green: 0.9, blue: 0.6)
        }
    }

    var surface: Color {
        switch self {
        case .standard: Color(.systemGray6)
        case .portastudio: Color(.sRGB, red: 0.12, green: 0.12, blue: 0.14)
        case .synth: Color(.sRGB, red: 0.95, green: 0.95, blue: 0.97)
        case .sampler: Color(.sRGB, red: 0.18, green: 0.18, blue: 0.16)
        }
    }
}

@Observable
@MainActor
final class ThemeManager {
    var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "selectedTheme") ?? ""
        self.current = AppTheme(rawValue: saved) ?? .standard
    }
}
