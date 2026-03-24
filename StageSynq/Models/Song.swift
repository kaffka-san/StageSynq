import Foundation

struct Song: Identifiable, Equatable {
    let id: UUID
    var name: String
    var durationMinutes: Int
    var durationSeconds: Int
    var order: Int
    var cardColorIndex: Int
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int,
        durationSeconds: Int,
        order: Int,
        cardColorIndex: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.durationSeconds = durationSeconds
        self.order = order
        self.cardColorIndex = Self.clampedColorIndex(cardColorIndex)
        self.notes = notes
    }
}

extension Song: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationMinutes
        case durationSeconds
        case order
        case cardColorIndex
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        order = try container.decode(Int.self, forKey: .order)
        cardColorIndex = Self.clampedColorIndex(try container.decodeIfPresent(Int.self, forKey: .cardColorIndex) ?? 0)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(order, forKey: .order)
        try container.encode(cardColorIndex, forKey: .cardColorIndex)
        try container.encode(notes, forKey: .notes)
    }

    private static func clampedColorIndex(_ value: Int) -> Int {
        min(max(0, value), 7)
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
