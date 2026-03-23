import Foundation

final class DefaultPlaylistStore: PlaylistManaging {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = directoryURL.appendingPathComponent("playlists.json")
    }

    func loadPlaylists() -> [Playlist] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return PredefinedPlaylists.all
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let playlists = try decoder.decode([Playlist].self, from: data)
            return playlists.isEmpty ? PredefinedPlaylists.all : playlists
        } catch {
            return PredefinedPlaylists.all
        }
    }

    func savePlaylists(_ playlists: [Playlist]) throws {
        let data = try encoder.encode(playlists)
        try data.write(to: fileURL, options: .atomic)
    }
}
