import Foundation
import Observation

@MainActor
@Observable
final class PlaylistDetailViewModel {
    // MARK: - Public properties

    let playlistID: UUID
    var selectedSongID: UUID?
    var validationMessage: String?
    /// Songs at or before the last finished track in the current show (stays dimmed after finish until toolbar reset).
    var completedSongIDs: Set<UUID> = []

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

    /// 1-based position of the song currently driving the timer (or list selection), for the timer UI.
    var currentTimerSongNumber: Int? {
        let id = timerViewModel.selectedSong?.id ?? selectedSongID
        guard let id, let idx = songs.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return idx + 1
    }
}

extension PlaylistDetailViewModel {
    // MARK: - Public methods

    func addSong(name: String, minutes: Int, seconds: Int, cardColorIndex: Int? = nil, notes: String = "") -> Bool {
        var allPlaylists = loadPlaylists()
        guard let playlistIndex = allPlaylists.firstIndex(where: { $0.id == playlistID }) else {
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateSong(name: trimmedName, minutes: minutes, seconds: seconds) else {
            return false
        }

        let nextOrder = allPlaylists[playlistIndex].songs.count
        let color = cardColorIndex.map { min(max(0, $0), 7) } ?? (nextOrder % 8)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let song = Song(
            name: trimmedName,
            durationMinutes: minutes,
            durationSeconds: seconds,
            order: nextOrder,
            cardColorIndex: color,
            notes: trimmedNotes
        )
        allPlaylists[playlistIndex].songs.append(song)
        allPlaylists[playlistIndex].updatedAt = .now
        return save(allPlaylists)
    }

    func updateSong(
        songID: UUID,
        name: String,
        minutes: Int,
        seconds: Int,
        cardColorIndex: Int,
        notes: String
    ) -> Bool {
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
        allPlaylists[playlistIndex].songs[songIndex].cardColorIndex = min(max(0, cardColorIndex), 7)
        allPlaylists[playlistIndex].songs[songIndex].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        allPlaylists[playlistIndex].updatedAt = .now

        let updatedSong = allPlaylists[playlistIndex].songs[songIndex]
        if timerViewModel.selectedSong?.id == updatedSong.id {
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
        }
        if let activeID = timerViewModel.selectedSong?.id, removedIDs.contains(activeID) {
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

    func onSongRowTapped(_ song: Song) {
        selectedSongID = song.id
        switch timerViewModel.state {
        case .running, .paused:
            return
        case .idle, .ready, .finished:
            timerViewModel.selectSong(song)
        }
    }

    /// Call when the timer reaches `.finished` (natural end or “Finish song”) so played rows stay dimmed.
    func registerSongsCompletedThrough(songID: UUID) {
        guard let idx = songs.firstIndex(where: { $0.id == songID }) else {
            return
        }
        for i in 0...idx {
            completedSongIDs.insert(songs[i].id)
        }
    }

    func clearCompletedSongsForNewShow() {
        completedSongIDs = []
    }

    /// Clears dimmed “played” state for the song and every song below it; used when starting playback (Play) from a completed row.
    func clearCompletedFromSongThroughEnd(songID: UUID) {
        guard let idx = songs.firstIndex(where: { $0.id == songID }) else {
            return
        }
        for i in idx..<songs.count {
            completedSongIDs.remove(songs[i].id)
        }
    }

    /// After a song ends, selects the next track (ready, not playing). No-op if there is no next song.
    func advanceToNextSongAfterFinishIfNeeded(finishedSongID: UUID) {
        guard let idx = songs.firstIndex(where: { $0.id == finishedSongID }) else {
            return
        }
        let nextIndex = idx + 1
        guard nextIndex < songs.count else {
            return
        }
        let next = songs[nextIndex]
        selectedSongID = next.id
        timerViewModel.selectSong(next)
    }

    func primaryTimerAction() {
        let highlight = songForID(selectedSongID)
        switch timerViewModel.state {
        case .running:
            timerViewModel.pause()
        case .paused:
            timerViewModel.startOrResume()
        case .idle, .ready, .finished:
            guard let song = highlight ?? timerViewModel.selectedSong else {
                return
            }
            if completedSongIDs.contains(song.id) {
                clearCompletedFromSongThroughEnd(songID: song.id)
            }
            if timerViewModel.selectedSong?.id != song.id {
                timerViewModel.selectSong(song)
            } else if timerViewModel.state == .finished {
                timerViewModel.reset()
            }
            timerViewModel.startOrResume()
        }
    }

    private func songForID(_ id: UUID?) -> Song? {
        guard let id else {
            return nil
        }
        return songs.first(where: { $0.id == id })
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
