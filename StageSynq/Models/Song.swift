import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var durationMinutes: Int
    var durationSeconds: Int
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int,
        durationSeconds: Int,
        order: Int
    ) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.durationSeconds = durationSeconds
        self.order = order
    }
}

extension Song {
    var totalSeconds: Int {
        (durationMinutes * 60) + durationSeconds
    }

    var formattedDuration: String {
        String(format: "%02d:%02d", durationMinutes, durationSeconds)
    }
}
