import Foundation
import Observation

@MainActor
@Observable
final class SongEditorViewModel {
    // MARK: - Public properties

    let mode: SongEditorMode
    var name: String
    var minutes: Int
    var seconds: Int
    var cardColorIndex: Int
    var notes: String
    var validationMessage: String?

    init(mode: SongEditorMode, song: Song? = nil) {
        self.mode = mode
        self.name = song?.name ?? ""
        self.minutes = song?.durationMinutes ?? 0
        self.seconds = song?.durationSeconds ?? 0
        self.cardColorIndex = song?.cardColorIndex ?? 0
        self.notes = song?.notes ?? ""
    }
}

extension SongEditorViewModel {
    var titleKey: String {
        switch mode {
        case .add:
            return "songEditor.title.add"
        case .edit:
            return "songEditor.title.edit"
        }
    }
}

extension SongEditorViewModel {
    // MARK: - Public methods

    func updateMinutes(from input: String) {
        let value = Int(input) ?? 0
        minutes = max(0, value)
    }

    func updateSeconds(from input: String) {
        let value = Int(input) ?? 0
        seconds = min(max(0, value), 59)
    }
}
