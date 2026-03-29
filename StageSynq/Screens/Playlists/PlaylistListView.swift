import SwiftUI

struct PlaylistListView: View {
    @Bindable var viewModel: PlaylistListViewModel
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            StageSyncStyle.background.ignoresSafeArea()

            if viewModel.isEmptyStateVisible {
                ContentUnavailableView(
                    "playlist.list.empty.title".localized,
                    systemImage: "music.note.list",
                    description: Text("playlist.list.empty.message".localized)
                )
                .foregroundStyle(.white)
            } else {
                List {
                    ForEach(Array(viewModel.playlists.enumerated()), id: \.element.id) { index, playlist in
                        playlistRow(playlist: playlist, color: StageSyncStyle.cardPalette[index % StageSyncStyle.cardPalette.count])
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: viewModel.deletePlaylist)
                    .onMove(perform: viewModel.reorderPlaylists)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("playlist.list.title".localized)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("settings.title".localized)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()
                Button {
                    viewModel.openCreateDialog()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(StageSyncStyle.accent)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
        .tint(StageSyncStyle.accent)
        .alert("playlist.create.title".localized, isPresented: $viewModel.isCreateDialogPresented) {
            TextField("playlist.name.placeholder".localized, text: $viewModel.draftPlaylistName)
            Button("common.cancel".localized, role: .cancel) { }
            Button("common.save".localized) {
                viewModel.createPlaylist()
            }
        } message: {
            Text(viewModel.validationError ?? "playlist.create.message".localized)
        }
        .alert(
            "playlist.rename.title".localized,
            isPresented: Binding(
                get: { viewModel.renamePlaylistID != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.renamePlaylistID = nil
                    }
                }
            )
        ) {
            TextField("playlist.name.placeholder".localized, text: $viewModel.renameDraft)
            Button("common.cancel".localized, role: .cancel) {
                viewModel.renamePlaylistID = nil
            }
            Button("common.save".localized) {
                viewModel.commitRename()
            }
        } message: {
            Text("playlist.rename.message".localized)
        }
    }

    @ViewBuilder
    func playlistRow(playlist: Playlist, color: Color) -> some View {
        Button {
            viewModel.openPlaylist(playlist)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(playlist.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.black)
                    Text(
                        String(
                            format: "playlist.list.songsCountFormat".localized,
                            playlist.songs.count
                        )
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.75))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                if let removalIndex = viewModel.playlists.firstIndex(where: { $0.id == playlist.id }) {
                    viewModel.deletePlaylist(at: IndexSet(integer: removalIndex))
                }
            } label: {
                Text("common.delete".localized)
            }

            Button {
                viewModel.beginRename(for: playlist)
            } label: {
                Text("common.rename".localized)
            }
            .tint(.orange)
        }
    }
}

private final class PreviewFlow: PlaylistListFlow {
    func showPlaylistDetail(playlistID: UUID) { }
}

private final class PreviewStore: PlaylistManaging {
    var previewData: [Playlist]

    init(previewData: [Playlist]) {
        self.previewData = previewData
    }

    func loadPlaylists() -> [Playlist] {
        previewData
    }

    func savePlaylists(_ playlists: [Playlist]) throws {
        previewData = playlists
    }
}

#Preview("Empty") {
    NavigationStack {
        PlaylistListView(
            viewModel: PlaylistListViewModel(
                flow: PreviewFlow(),
                store: PreviewStore(previewData: [])
            )
        )
    }
}

#Preview("Populated") {
    let songs = [Song(name: "Track A", durationMinutes: 2, durationSeconds: 45, order: 0)]
    let playlists = [Playlist(name: "Opening Set", songs: songs)]
    return NavigationStack {
        PlaylistListView(
            viewModel: PlaylistListViewModel(
                flow: PreviewFlow(),
                store: PreviewStore(previewData: playlists)
            )
        )
    }
}
