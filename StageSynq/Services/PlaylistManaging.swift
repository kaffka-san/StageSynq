import Foundation

protocol PlaylistManaging {
    func loadPlaylists() -> [Playlist]
    func savePlaylists(_ playlists: [Playlist]) throws
}
