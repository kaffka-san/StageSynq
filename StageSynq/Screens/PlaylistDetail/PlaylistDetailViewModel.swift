import Foundation
import Observation

@MainActor
@Observable
final class PlaylistDetailViewModel {
    // MARK: - Public properties

    let playlistID: UUID
    var selectedSongID: UUID?
    var validationMessage: String?

    // MARK: - Private properties

    private let loadPlaylists: () -> [Playlist]
    private let savePlaylists: ([Playlist]) -> Bool
    private let timerViewModel: SongTimerViewModel

    init(
        playlistID: UUID,
        timerViewModel: SongTimerViewModel,
        loadPlaylists: @escaping () -> [Playlist],
        savePlaylists: @escaping ([Playlist]) -> Bool
    ) {
        self.playlistID = playlistID
        self.timerViewModel = timerViewModel
        self.loadPlaylists = loadPlaylists
        self.savePlaylists = savePlaylists
    }
}

extension PlaylistDetailViewModel {
    var playlist: Playlist? {
        loadPlaylists().first(where: { $0.id == playlistID })
    }

    var songs: [Song] {
        playlist?.songs.sorted(by: { $0.order < $1.order }) ?? []
    }
}

extension PlaylistDetailViewModel {
    // MARK: - Public methods

    func addSong(name: String, minutes: Int, seconds: Int) -> Bool {
        var allPlaylists = loadPlaylists()
        guard let playlistIndex = allPlaylists.firstIndex(where: { $0.id == playlistID }) else {
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateSong(name: trimmedName, minutes: minutes, seconds: seconds) else {
            return false
        }

        let nextOrder = allPlaylists[playlistIndex].songs.count
        let song = Song(
            name: trimmedName,
            durationMinutes: minutes,
            durationSeconds: seconds,
            order: nextOrder
        )
        allPlaylists[playlistIndex].songs.append(song)
        allPlaylists[playlistIndex].updatedAt = .now
        return save(allPlaylists)
    }

    func updateSong(songID: UUID, name: String, minutes: Int, seconds: Int) -> Bool {
        var allPlaylists = loadPlaylists()
        guard
            let playlistIndex = allPlaylists.firstIndex(where: { $0.id == playlistID }),
            let songIndex = allPlaylists[playlistIndex].songs.firstIndex(where: { $0.id == songID })
        else {
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateSong(name: trimmedName, minutes: minutes, seconds: seconds) else {
            return false
        }

        allPlaylists[playlistIndex].songs[songIndex].name = trimmedName
        allPlaylists[playlistIndex].songs[songIndex].durationMinutes = minutes
        allPlaylists[playlistIndex].songs[songIndex].durationSeconds = seconds
        allPlaylists[playlistIndex].updatedAt = .now

        let updatedSong = allPlaylists[playlistIndex].songs[songIndex]
        if selectedSongID == updatedSong.id {
            timerViewModel.selectSong(updatedSong)
        }

        return save(allPlaylists)
    }

    func deleteSong(at offsets: IndexSet) {
        var allPlaylists = loadPlaylists()
        guard let playlistIndex = allPlaylists.firstIndex(where: { $0.id == playlistID }) else {
            return
        }

        let orderedSongs = allPlaylists[playlistIndex].songs.sorted(by: { $0.order < $1.order })
        let removedSongs = offsets.compactMap { index in
            orderedSongs.indices.contains(index) ? orderedSongs[index] : nil
        }
        let removedIDs = Set(removedSongs.map(\.id))
        allPlaylists[playlistIndex].songs.removeAll(where: { removedIDs.contains($0.id) })
        normalizeOrder(for: &allPlaylists[playlistIndex])
        allPlaylists[playlistIndex].updatedAt = .now

        if let selectedSongID, removedIDs.contains(selectedSongID) {
            self.selectedSongID = nil
            timerViewModel.reset()
            timerViewModel.selectedSong = nil
            timerViewModel.state = .idle
            timerViewModel.remainingSeconds = 0
        }

        _ = save(allPlaylists)
    }

    func reorderSongs(from source: IndexSet, to destination: Int) {
        var allPlaylists = loadPlaylists()
        guard let playlistIndex = allPlaylists.firstIndex(where: { $0.id == playlistID }) else {
            return
        }

        var sortedSongs = allPlaylists[playlistIndex].songs.sorted(by: { $0.order < $1.order })
        sortedSongs.move(fromOffsets: source, toOffset: destination)
        for index in sortedSongs.indices {
            sortedSongs[index].order = index
        }

        allPlaylists[playlistIndex].songs = sortedSongs
        allPlaylists[playlistIndex].updatedAt = .now
        _ = save(allPlaylists)
    }

    func selectSong(_ song: Song) {
        selectedSongID = song.id
        timerViewModel.selectSong(song)
    }
}

private extension PlaylistDetailViewModel {
    // MARK: - Private methods

    func validateSong(name: String, minutes: Int, seconds: Int) -> Bool {
        guard !name.isEmpty else {
            validationMessage = "song.validation.nameRequired".localized
            return false
        }
        guard minutes >= 0 else {
            validationMessage = "song.validation.invalidMinutes".localized
            return false
        }
        guard (0...59).contains(seconds) else {
            validationMessage = "song.validation.invalidSeconds".localized
            return false
        }
        guard (minutes * 60 + seconds) > 0 else {
            validationMessage = "song.validation.durationRequired".localized
            return false
        }
        validationMessage = nil
        return true
    }

    func save(_ playlists: [Playlist]) -> Bool {
        let didSave = savePlaylists(playlists)
        if !didSave {
            validationMessage = "common.error.saveFailed".localized
        }
        return didSave
    }

    func normalizeOrder(for playlist: inout Playlist) {
        let sortedSongs = playlist.songs.sorted(by: { $0.order < $1.order })
        playlist.songs = sortedSongs.enumerated().map { index, song in
            var mutableSong = song
            mutableSong.order = index
            return mutableSong
        }
    }
}
