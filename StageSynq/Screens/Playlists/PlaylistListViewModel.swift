import Foundation
import Observation

@MainActor
@Observable
final class PlaylistListViewModel {
    // MARK: - Public properties

    var playlists: [Playlist]
    var draftPlaylistName: String
    var isCreateDialogPresented: Bool
    var renamePlaylistID: UUID?
    var renameDraft: String
    var validationError: String?

    // MARK: - Private properties

    private let flow: PlaylistListFlow
    private let store: PlaylistManaging

    init(flow: PlaylistListFlow, store: PlaylistManaging) {
        self.flow = flow
        self.store = store
        self.playlists = store.loadPlaylists().sorted(by: { $0.updatedAt > $1.updatedAt })
        self.draftPlaylistName = ""
        self.isCreateDialogPresented = false
        self.renamePlaylistID = nil
        self.renameDraft = ""
        self.validationError = nil
    }
}

extension PlaylistListViewModel {
    var isEmptyStateVisible: Bool {
        playlists.isEmpty
    }
}

extension PlaylistListViewModel {
    // MARK: - Public methods

    func openCreateDialog() {
        draftPlaylistName = ""
        validationError = nil
        isCreateDialogPresented = true
    }

    func createPlaylist() {
        let trimmedName = draftPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "playlist.validation.nameRequired".localized
            return
        }

        let playlist = Playlist(name: trimmedName)
        playlists.insert(playlist, at: 0)
        persist()
        isCreateDialogPresented = false
        flow.showPlaylistDetail(playlistID: playlist.id)
    }

    func deletePlaylist(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        persist()
    }

    func reorderPlaylists(from source: IndexSet, to destination: Int) {
        playlists.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func openPlaylist(_ playlist: Playlist) {
        flow.showPlaylistDetail(playlistID: playlist.id)
    }

    func beginRename(for playlist: Playlist) {
        renamePlaylistID = playlist.id
        renameDraft = playlist.name
    }

    func commitRename() {
        guard let renamePlaylistID else {
            return
        }

        let trimmedName = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "playlist.validation.nameRequired".localized
            return
        }

        guard let index = playlists.firstIndex(where: { $0.id == renamePlaylistID }) else {
            self.renamePlaylistID = nil
            return
        }

        playlists[index].name = trimmedName
        playlists[index].updatedAt = .now
        self.renamePlaylistID = nil
        persist()
    }
}

private extension PlaylistListViewModel {
    // MARK: - Private methods

    func persist() {
        do {
            try store.savePlaylists(playlists)
            validationError = nil
        } catch {
            validationError = "common.error.saveFailed".localized
        }
    }
}
