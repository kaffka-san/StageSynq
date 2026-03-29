import SwiftUI

enum AppSettings {
    static let fontSizePresetKey = "app.settings.fontSizePreset"
    static let timerUrgentSecondsKey = "app.settings.timerUrgentSeconds"
    static let timerAdjustStepKey = "app.settings.timerAdjustStep"

    static let defaultFontSizePreset = 1
    static let defaultTimerUrgentSeconds = 30
    static let defaultTimerAdjustStep = 5
}

enum AppFontSizePreset: Int, CaseIterable, Identifiable {
    case smaller = 0
    case standard = 1
    case larger = 2
    case extraLarge = 3

    var id: Int { rawValue }

    var localizationKey: String {
        switch self {
        case .smaller: return "settings.fontSize.smaller"
        case .standard: return "settings.fontSize.standard"
        case .larger: return "settings.fontSize.larger"
        case .extraLarge: return "settings.fontSize.extraLarge"
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .smaller: return .small
        case .standard: return .medium
        case .larger: return .large
        case .extraLarge: return .xLarge
        }
    }
}

enum TimerAdjustStepIcon {
    static func systemName(forward: Bool, seconds: Int) -> String {
        if forward {
            switch seconds {
            case 5: return "goforward.5"
            case 10: return "goforward.10"
            case 15: return "goforward.15"
            case 30: return "goforward.30"
            case 45: return "goforward"
            case 60: return "goforward.60"
            default: return "goforward"
            }
        } else {
            switch seconds {
            case 5: return "gobackward.5"
            case 10: return "gobackward.10"
            case 15: return "gobackward.15"
            case 30: return "gobackward.30"
            case 45: return "gobackward"
            case 60: return "gobackward.60"
            default: return "gobackward"
            }
        }
    }
}
