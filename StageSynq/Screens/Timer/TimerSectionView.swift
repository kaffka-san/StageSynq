import SwiftUI

struct TimerSectionView: View {
    private static let countdownFontSize: CGFloat = 54 * 1.4
    private static let actionButtonMinHeight: CGFloat = 32

    @AppStorage(AppSettings.timerUrgentSecondsKey) private var urgentThresholdSeconds = AppSettings.defaultTimerUrgentSeconds
    @AppStorage(AppSettings.timerAdjustStepKey) private var adjustStepSeconds = AppSettings.defaultTimerAdjustStep

    @Bindable var viewModel: SongTimerViewModel
    /// Inset for home indicator; background still extends under safe area.
    var bottomSafeInset: CGFloat = 0
    var songNumber: Int? = nil
    var onPrimaryAction: (() -> Void)? = nil
    var isPlayDisabled: Bool? = nil
    var isFinishDisabled: Bool? = nil

    var body: some View {
        VStack(spacing: 10) {
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
                    viewModel.adjustRemainingTime(bySeconds: -adjustStepSeconds)
                } label: {
                    Image(systemName: TimerAdjustStepIcon.systemName(forward: false, seconds: adjustStepSeconds))
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .controlSize(.small)
                .tint(.white.opacity(0.85))
                .disabled(!canAdjustRemainingTime)
                .accessibilityLabel(
                    String(format: "timer.adjust.minus.accessibility".localized, adjustStepSeconds)
                )

                Text(viewModel.remainingTimeLabel)
                    .font(.system(size: Self.countdownFontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(countdownForegroundStyle)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                Button {
                    viewModel.adjustRemainingTime(bySeconds: adjustStepSeconds)
                } label: {
                    Image(systemName: TimerAdjustStepIcon.systemName(forward: true, seconds: adjustStepSeconds))
                        .font(.title3.weight(.semibold))
                        .frame(width: 32, height: 32)
                }
                .controlSize(.small)
                .tint(.white.opacity(0.85))
                .disabled(!canAdjustRemainingTime)
                .accessibilityLabel(
                    String(format: "timer.adjust.plus.accessibility".localized, adjustStepSeconds)
                )
            }

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
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, bottomSafeInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background {
            ZStack {
                Self.liquidGlassDockedShape
                    .fill(Color.black.opacity(0.72))
                Self.liquidGlassDockedShape
                    .fill(.ultraThinMaterial)
                    .opacity(0.78)
                Self.liquidGlassDockedShape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                Self.liquidGlassDockedShape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .opacity(0.94)
        }
    }

    /// Top-rounded bar, square bottom — flush with screen bottom.
    private static var liquidGlassDockedShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 28,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: 28
            ),
            style: .continuous
        )
    }
}

private extension TimerSectionView {
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
        if remaining > 0, remaining <= urgentThresholdSeconds {
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
    return TimerSectionView(viewModel: timerVM, bottomSafeInset: 34)
        .frame(height: 320)
        .background(StageSyncStyle.background)
}

#Preview("Idle") {
    TimerSectionView(viewModel: SongTimerViewModel(), bottomSafeInset: 34)
        .frame(height: 320)
        .background(StageSyncStyle.background)
}
