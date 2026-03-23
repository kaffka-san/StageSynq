//
//  StageSynqTests.swift
//  StageSynqTests
//
//  Created by Lenina Anastasia on 23.03.2026.
//

import Testing
@testable import StageSynq

struct StageSynqTests {
    @MainActor
    @Test
    func timerTransitionsFromReadyToFinished() async throws {
        let haptics = TestHapticsManager()
        let viewModel = SongTimerViewModel(hapticsManager: haptics)
        viewModel.selectSong(Song(name: "Quick", durationMinutes: 0, durationSeconds: 1, order: 0))

        viewModel.startOrResume()
        try await Task.sleep(for: .milliseconds(1_300))
        viewModel.appDidBecomeActive()

        #expect(viewModel.state == .finished)
        #expect(viewModel.remainingSeconds == 0)
        #expect(haptics.notificationCount == 1)
    }

    @MainActor
    @Test
    func addSongValidationRejectsZeroDuration() {
        let timerViewModel = SongTimerViewModel()
        let source = TestPlaylistsSource(playlists: [Playlist(name: "A")])
        let sut = PlaylistDetailViewModel(
            playlistID: source.playlists[0].id,
            timerViewModel: timerViewModel,
            loadPlaylists: { source.playlists },
            savePlaylists: { playlists in
                source.playlists = playlists
                return true
            }
        )

        let didAdd = sut.addSong(name: "Intro", minutes: 0, seconds: 0)

        #expect(didAdd == false)
        #expect(source.playlists[0].songs.isEmpty)
        #expect(sut.validationMessage == "song.validation.durationRequired".localized)
    }
}

private final class TestHapticsManager: HapticsManaging {
    var notificationCount: Int = 0

    func notifySuccess() {
        notificationCount += 1
    }
}

private final class TestPlaylistsSource {
    var playlists: [Playlist]

    init(playlists: [Playlist]) {
        self.playlists = playlists
    }
}
