import SwiftUI

struct TimerSectionView: View {
    private static let countdownFontSize: CGFloat = 54 * 1.4
    private static let actionButtonMinHeight: CGFloat = 32

    @Bindable var viewModel: SongTimerViewModel
    var songNumber: Int? = nil
    var onPrimaryAction: (() -> Void)? = nil
    var isPlayDisabled: Bool? = nil
    var isFinishDisabled: Bool? = nil

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    if let songNumber {
                        Text(
                            String(format: "timer.songNumberFormat".localized, songNumber)
                        )
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(StageSyncStyle.accent)
                    }

                    Text(viewModel.selectedSongName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: stateIconSystemName)
                        .font(.title)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(stateColor)
                        .accessibilityLabel(viewModel.stateLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .center, spacing: 10) {
                Button {
                    viewModel.adjustRemainingTime(bySeconds: -5)
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .controlSize(.small)
                .tint(.white.opacity(0.85))
                .disabled(!canAdjustRemainingTime)
                .accessibilityLabel("timer.adjust.minus5.accessibility".localized)
               // Spacer()
                Text(viewModel.remainingTimeLabel)
                    .font(.system(size: Self.countdownFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(countdownForegroundStyle)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
              //  Spacer()

                Button {
                    viewModel.adjustRemainingTime(bySeconds: 5)
                } label: {
                    Image(systemName: "goforward.5")
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .controlSize(.small)
                .tint(.white.opacity(0.85))
                .disabled(!canAdjustRemainingTime)
                .accessibilityLabel("timer.adjust.plus5.accessibility".localized)
            }
            .padding(.horizontal, 26)

            HStack {
                Text("timer.originalDuration".localized)
                    .foregroundStyle(StageSyncStyle.mutedText)
                Text(viewModel.originalDurationLabel)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            .font(.caption)

            HStack(spacing: 24) {
                Button(action: primaryAction) {
                    Text(primaryButtonTitle.localized)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: Self.actionButtonMinHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(StageSyncStyle.accent)
                .foregroundStyle(.black)
                .disabled(playDisabled)

                Button {
                    viewModel.finishSong()
                } label: {
                    Text("timer.action.finishSong".localized)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: Self.actionButtonMinHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(finishDisabled)
            }
            .padding(.bottom, 20)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.black.opacity(0.75))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
        }
    }
}

private extension TimerSectionView {
    private static let urgentRemainingSeconds = 30

    var playDisabled: Bool {
        isPlayDisabled ?? (viewModel.state == .idle)
    }

    var finishDisabled: Bool {
        isFinishDisabled ?? (viewModel.selectedSong == nil || viewModel.state == .finished)
    }

    var canAdjustRemainingTime: Bool {
        guard viewModel.selectedSong != nil else { return false }
        switch viewModel.state {
        case .ready, .running, .paused:
            return true
        case .idle, .finished:
            return false
        }
    }

    var countdownForegroundStyle: Color {
        let remaining = viewModel.remainingSeconds
        if remaining > 0, remaining <= Self.urgentRemainingSeconds {
            return .red
        }
        return .white
    }

    var stateIconSystemName: String {
        switch viewModel.state {
        case .idle:
            return "circle.dashed"
        case .ready:
            return "play.circle"
        case .running:
            return "play.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .finished:
            return "checkmark.circle.fill"
        }
    }

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
        if let onPrimaryAction {
            onPrimaryAction()
        } else if viewModel.state == .running {
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
