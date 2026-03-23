import SwiftUI

struct TimerSectionView: View {
    @Bindable var viewModel: SongTimerViewModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.selectedSongName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Text(viewModel.stateLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stateColor)
            }

            Text(viewModel.remainingTimeLabel)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("timer.originalDuration".localized)
                    .foregroundStyle(StageSyncStyle.mutedText)
                Text(viewModel.originalDurationLabel)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            .font(.caption)

            HStack(spacing: 10) {
                Button(action: primaryAction) {
                    Text(primaryButtonTitle.localized)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(StageSyncStyle.accent)
                .foregroundStyle(.black)
                .disabled(viewModel.state == .idle)

                Button("timer.action.reset".localized) {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .font(.headline.weight(.semibold))
                .tint(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .disabled(viewModel.state == .idle)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

private extension TimerSectionView {
    var primaryButtonTitle: String {
        switch viewModel.state {
        case .running:
            return "timer.action.pause"
        default:
            return "timer.action.play"
        }
    }

    var stateColor: Color {
        switch viewModel.state {
        case .running:
            return .green
        case .paused:
            return .orange
        case .finished:
            return .red
        case .ready, .idle:
            return StageSyncStyle.mutedText
        }
    }

    func primaryAction() {
        if viewModel.state == .running {
            viewModel.pause()
        } else {
            viewModel.startOrResume()
        }
    }
}

#Preview("Ready") {
    let timerVM = SongTimerViewModel()
    timerVM.selectSong(Song(name: "Intro", durationMinutes: 2, durationSeconds: 30, order: 0))
    return TimerSectionView(viewModel: timerVM)
        .padding()
        .background(.black)
}

#Preview("Idle") {
    TimerSectionView(viewModel: SongTimerViewModel())
        .padding()
        .background(.black)
}
