import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppCoordinator: PlaylistListFlow {
    enum Route: Hashable {
        case playlistDetail(UUID)
    }

    var navigationPath: [Route]
    var listViewModel: PlaylistListViewModel
    let timerViewModel: SongTimerViewModel

    private let store: PlaylistManaging

    init(store: PlaylistManaging = DefaultPlaylistStore()) {
        self.store = store
        self.navigationPath = []
        self.timerViewModel = SongTimerViewModel()
        self.listViewModel = PlaylistListViewModel(flow: DummyFlow(), store: store)
        self.listViewModel = PlaylistListViewModel(flow: self, store: store)
    }

    func showPlaylistDetail(playlistID: UUID) {
        navigationPath.append(.playlistDetail(playlistID))
    }

    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .playlistDetail(let playlistID):
            PlaylistDetailView(
                viewModel: makePlaylistDetailViewModel(playlistID: playlistID),
                timerViewModel: timerViewModel
            )
        }
    }
}

private extension AppCoordinator {
    func makePlaylistDetailViewModel(playlistID: UUID) -> PlaylistDetailViewModel {
        PlaylistDetailViewModel(
            playlistID: playlistID,
            timerViewModel: timerViewModel,
            loadPlaylists: { [weak self] in
                self?.listViewModel.playlists ?? []
            },
            savePlaylists: { [weak self] updatedPlaylists in
                guard let self else {
                    return false
                }

                self.listViewModel.playlists = updatedPlaylists.sorted(by: { $0.updatedAt > $1.updatedAt })
                do {
                    try self.store.savePlaylists(updatedPlaylists)
                    return true
                } catch {
                    return false
                }
            }
        )
    }
}

@MainActor
private final class DummyFlow: PlaylistListFlow {
    func showPlaylistDetail(playlistID: UUID) { }
}
