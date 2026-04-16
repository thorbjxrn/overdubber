import SwiftUI
import Observation

enum AppTheme: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case tascam = "TASCAM"
    case op1 = "OP-1"
    case sp404 = "SP-404"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .standard: .red
        case .tascam: Color(.sRGB, red: 0.8, green: 0.15, blue: 0.15)
        case .op1: Color(.sRGB, red: 0.2, green: 0.6, blue: 1.0)
        case .sp404: Color(.sRGB, red: 0.9, green: 0.5, blue: 0.1)
        }
    }

    var waveform: Color {
        switch self {
        case .standard: .red
        case .tascam: Color(.sRGB, red: 0.9, green: 0.2, blue: 0.2)
        case .op1: Color(.sRGB, red: 0.3, green: 0.7, blue: 1.0)
        case .sp404: Color(.sRGB, red: 1.0, green: 0.6, blue: 0.2)
        }
    }

    var record: Color {
        switch self {
        case .standard: .red
        case .tascam: Color(.sRGB, red: 0.85, green: 0.1, blue: 0.1)
        case .op1: Color(.sRGB, red: 1.0, green: 0.3, blue: 0.3)
        case .sp404: Color(.sRGB, red: 0.9, green: 0.3, blue: 0.1)
        }
    }

    var surface: Color {
        switch self {
        case .standard: Color(.systemGray6)
        case .tascam: Color(.sRGB, red: 0.12, green: 0.12, blue: 0.14)
        case .op1: Color(.sRGB, red: 0.95, green: 0.95, blue: 0.97)
        case .sp404: Color(.sRGB, red: 0.18, green: 0.18, blue: 0.16)
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
