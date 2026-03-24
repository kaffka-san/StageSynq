import SwiftUI

struct PlaylistDetailView: View {
    @Bindable var viewModel: PlaylistDetailViewModel
    @Bindable var timerViewModel: SongTimerViewModel
    @State private var editorViewModel: SongEditorViewModel?
    @State private var flashlight = FlashlightController()
    @AppStorage("playlistDetail.showSongNotes") private var showSongNotes = true

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
                TimerSectionView(
                    viewModel: timerViewModel,
                    songNumber: viewModel.currentTimerSongNumber,
                    onPrimaryAction: { viewModel.primaryTimerAction() },
                    isPlayDisabled: playButtonDisabled,
                    isFinishDisabled: finishButtonDisabled
                )
                .frame(height: timerHeight)
            }
           
        }
        .navigationTitle(viewModel.playlist?.name ?? "playlist.detail.fallbackTitle".localized)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    flashlight.toggle()
                } label: {
                    Label {
                        Text("playlist.detail.flashlight".localized)
                    } icon: {
                        Image(systemName: flashlight.isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    }
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(flashlight.isOn ? Color(red: 1, green: 0.92, blue: 0.35) : StageSyncStyle.accent)
                .foregroundStyle(.black)
                .controlSize(.large)
                .accessibilityLabel("playlist.detail.flashlight.accessibility".localized)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSongNotes.toggle()
                } label: {
                    Image(systemName: showSongNotes ? "eye" : "eye.slash")
                }
                .tint(showSongNotes ? StageSyncStyle.accent : StageSyncStyle.mutedText)
                .accessibilityLabel("playlist.detail.notes.toggle.accessibility".localized)

                Button {
                    viewModel.clearCompletedSongsForNewShow()
                    timerViewModel.reset()
                } label: {
                    Label("playlist.detail.resetState".localized, systemImage: "arrow.counterclockwise")
                }
                .disabled(toolbarResetStateDisabled)

                Button {
                    editorViewModel = SongEditorViewModel(mode: .add)
                } label: {
                    Label("song.add.title".localized, systemImage: "plus.circle.fill")
                }
            }
        }
        .tint(StageSyncStyle.accent)
        .sheet(item: $editorViewModel) { vm in
            SongEditorView(viewModel: vm) { name, minutes, seconds, cardColorIndex, notes in
                switch vm.mode {
                case .add:
                    let didSave = viewModel.addSong(
                        name: name,
                        minutes: minutes,
                        seconds: seconds,
                        cardColorIndex: cardColorIndex,
                        notes: notes
                    )
                    vm.validationMessage = didSave ? nil : viewModel.validationMessage
                    return didSave
                case .edit(let songID):
                    let didSave = viewModel.updateSong(
                        songID: songID,
                        name: name,
                        minutes: minutes,
                        seconds: seconds,
                        cardColorIndex: cardColorIndex,
                        notes: notes
                    )
                    vm.validationMessage = didSave ? nil : viewModel.validationMessage
                    return didSave
                }
            }
        }
        .onAppear {
            if viewModel.selectedSongID == nil, let first = viewModel.songs.first {
                viewModel.selectedSongID = first.id
            }
            if timerViewModel.state == .idle, timerViewModel.selectedSong == nil,
               let id = viewModel.selectedSongID,
               let song = viewModel.songs.first(where: { $0.id == id }) {
                timerViewModel.selectSong(song)
            }
        }
        .onChange(of: timerViewModel.state) { _, newValue in
            guard newValue == .finished, let id = timerViewModel.selectedSong?.id else {
                return
            }
            viewModel.registerSongsCompletedThrough(songID: id)
            viewModel.advanceToNextSongAfterFinishIfNeeded(finishedSongID: id)
        }
        .onDisappear {
            flashlight.turnOffIfNeeded()
        }
    }
}

private enum PlayingIconStyle {
    static let backgroundFill = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let iconGradient = LinearGradient(
        colors: [
            Color(white: 0.62),
            Color(white: 0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private extension PlaylistDetailView {
    var playButtonDisabled: Bool {
        switch timerViewModel.state {
        case .running, .paused, .ready, .finished:
            return false
        case .idle:
            return viewModel.selectedSongID == nil && timerViewModel.selectedSong == nil
        }
    }

    var finishButtonDisabled: Bool {
        timerViewModel.selectedSong == nil || timerViewModel.state == .finished
    }

    var toolbarResetStateDisabled: Bool {
        timerViewModel.state == .idle && timerViewModel.selectedSong == nil
    }

    var songsListSection: some View {
        Group {
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
                        songRow(index: index, song: song, showNotes: showSongNotes)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                    .onMove(perform: viewModel.reorderSongs)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    func songRow(index: Int, song: Song, showNotes: Bool) -> some View {
        let color = SongCardPalette.swiftUIColor(at: song.cardColorIndex)
        let isTimerActive = timerViewModel.state == .running || timerViewModel.state == .paused
        let playingSongID = isTimerActive ? timerViewModel.selectedSong?.id : nil
        let playingIndex = playingSongID.flatMap { id in
            viewModel.songs.firstIndex(where: { $0.id == id })
        }
        let isAbovePlaying = playingIndex.map { index < $0 } ?? false
        let isCompleted = viewModel.completedSongIDs.contains(song.id)
        let isDimmed = isCompleted || isAbovePlaying
        let isPlayingThisSong = playingSongID == song.id

        HStack(alignment: .center, spacing: 12) {
          

            Text("\(index + 1).")
                .font(.headline.weight(.bold))
                .foregroundStyle(.black.opacity(isDimmed ? 0.4 : 0.85))

            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black.opacity(isDimmed ? 0.45 : 1))
                Text(song.formattedDuration)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black.opacity(isDimmed ? 0.35 : 0.75))
                if showNotes, !song.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(song.notes)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.black.opacity(isDimmed ? 0.4 : 0.88))
                        .lineLimit(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()
            ZStack {
                if isPlayingThisSong {
                    Image(systemName: "waveform")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: timerViewModel.state == .running)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(PlayingIconStyle.backgroundFill)
                                .frame(width: 40, height: 20)
                                .opacity(0.8)
                        )
                        .accessibilityLabel("playlist.song.playing.accessibility".localized)
                }
            }
            Image(systemName: viewModel.selectedSongID == song.id ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(.black.opacity(isDimmed ? 0.4 : 0.75))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .opacity(isDimmed ? 0.55 : 1)
        )
        .contentShape(Rectangle())
        .accessibilityLabel(
            String(format: "playlist.song.row.accessibility".localized, index + 1, song.name, song.formattedDuration)
        )
        .onTapGesture {
            viewModel.onSongRowTapped(song)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                if let rowIndex = viewModel.songs.firstIndex(where: { $0.id == song.id }) {
                    viewModel.deleteSong(at: IndexSet(integer: rowIndex))
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
