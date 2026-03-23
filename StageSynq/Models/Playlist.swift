import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var songs: [Song]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        songs: [Song] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.songs = songs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
