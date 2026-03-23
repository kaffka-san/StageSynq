import SwiftUI

struct PlaylistDetailView: View {
    @Bindable var viewModel: PlaylistDetailViewModel
    @Bindable var timerViewModel: SongTimerViewModel
    @State private var editorViewModel: SongEditorViewModel?

    var body: some View {
        GeometryReader { proxy in
            let timerHeight = max(140, proxy.size.height * 0.2)

            ZStack {
                StageSyncStyle.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    songsListSection
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .safeAreaInset(edge: .bottom) {
                TimerSectionView(viewModel: timerViewModel)
                    .frame(height: timerHeight)
            }
           
        }
        .navigationTitle(viewModel.playlist?.name ?? "playlist.detail.fallbackTitle".localized)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("song.add.title".localized) {
                    editorViewModel = SongEditorViewModel(mode: .add)
                }
            }
        }
        .tint(StageSyncStyle.accent)
        .sheet(item: $editorViewModel) { vm in
            SongEditorView(viewModel: vm) { name, minutes, seconds in
                switch vm.mode {
                case .add:
                    let didSave = viewModel.addSong(name: name, minutes: minutes, seconds: seconds)
                    vm.validationMessage = didSave ? nil : viewModel.validationMessage
                    return didSave
                case .edit(let songID):
                    let didSave = viewModel.updateSong(
                        songID: songID,
                        name: name,
                        minutes: minutes,
                        seconds: seconds
                    )
                    vm.validationMessage = didSave ? nil : viewModel.validationMessage
                    return didSave
                }
            }
        }
    }
}

private extension PlaylistDetailView {
    var songsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("playlist.detail.songs.title".localized)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            if viewModel.songs.isEmpty {
                ContentUnavailableView(
                    "playlist.detail.empty.title".localized,
                    systemImage: "music.note",
                    description: Text("playlist.detail.empty.message".localized)
                )
                .foregroundStyle(.white)
            } else {
                List {
                    ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                        songRow(song: song, color: StageSyncStyle.cardPalette[index % StageSyncStyle.cardPalette.count])
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                    .onMove(perform: viewModel.reorderSongs)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    func songRow(song: Song, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
                Text(song.formattedDuration)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black.opacity(0.75))
            }

            Spacer()

            Image(systemName: viewModel.selectedSongID == song.id ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(.black.opacity(0.75))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectSong(song)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                if let index = viewModel.songs.firstIndex(where: { $0.id == song.id }) {
                    viewModel.deleteSong(at: IndexSet(integer: index))
                }
            } label: {
                Text("common.delete".localized)
            }

            Button {
                editorViewModel = SongEditorViewModel(mode: .edit(songID: song.id), song: song)
            } label: {
                Text("common.edit".localized)
            }
            .tint(.orange)
        }
    }
}

extension SongEditorViewModel: Identifiable {
    var id: String {
        switch mode {
        case .add:
            return "add"
        case .edit(let songID):
            return "edit_\(songID.uuidString)"
        }
    }
}

#Preview {
    let songs = [
        Song(name: "Intro", durationMinutes: 1, durationSeconds: 15, order: 0),
        Song(name: "Finale", durationMinutes: 2, durationSeconds: 40, order: 1),
        Song(name: "Finale", durationMinutes: 2, durationSeconds: 40, order: 1),
        Song(name: "Finale", durationMinutes: 2, durationSeconds: 40, order: 1),
        Song(name: "Finale", durationMinutes: 2, durationSeconds: 40, order: 1),
        Song(name: "Finale", durationMinutes: 2, durationSeconds: 40, order: 1),
        Song(name: "Finale", durationMinutes: 2, durationSeconds: 40, order: 1)
    ]
    let playlist = Playlist(name: "Preview Playlist", songs: songs)
    let timerViewModel = SongTimerViewModel()

    return NavigationStack {
        PlaylistDetailView(
            viewModel: PlaylistDetailViewModel(
                playlistID: playlist.id,
                timerViewModel: timerViewModel,
                loadPlaylists: { [playlist] in [playlist] },
                savePlaylists: { _ in true }
            ),
            timerViewModel: timerViewModel
        )
    }
}
