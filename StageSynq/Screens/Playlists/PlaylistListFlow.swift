import Foundation

@MainActor
protocol PlaylistListFlow: AnyObject {
    func showPlaylistDetail(playlistID: UUID)
}
