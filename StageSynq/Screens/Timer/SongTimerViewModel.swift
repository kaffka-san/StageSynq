import Foundation
import Observation

enum SongTimerState: String {
    case idle
    case ready
    case running
    case paused
    case finished
}

@MainActor
@Observable
final class SongTimerViewModel {
    var selectedSong: Song?
    var state: SongTimerState
    var remainingSeconds: Int

    private let hapticsManager: HapticsManaging
    private var endDate: Date?
    private var tickerTask: Task<Void, Never>?

    init(hapticsManager: HapticsManaging = DefaultHapticsManager()) {
        self.hapticsManager = hapticsManager
        self.state = .idle
        self.remainingSeconds = 0
    }
}

extension SongTimerViewModel {
    var selectedSongName: String {
        selectedSong?.name ?? "timer.noSelection".localized
    }

    var originalDurationLabel: String {
        guard let selectedSong else {
            return "timer.originalDuration.empty".localized
        }

        return String(format: "%02d:%02d", selectedSong.durationMinutes, selectedSong.durationSeconds)
    }

    var remainingTimeLabel: String {
        let minutes = max(0, remainingSeconds) / 60
        let seconds = max(0, remainingSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var stateLabel: String {
        switch state {
        case .idle:
            return "timer.state.idle".localized
        case .ready:
            return "timer.state.ready".localized
        case .running:
            return "timer.state.running".localized
        case .paused:
            return "timer.state.paused".localized
        case .finished:
            return "timer.state.finished".localized
        }
    }
}

extension SongTimerViewModel {
    func selectSong(_ song: Song) {
        stopTicker()
        selectedSong = song
        remainingSeconds = song.totalSeconds
        state = .ready
        endDate = nil
    }

    func startOrResume() {
        guard selectedSong != nil else {
            state = .idle
            return
        }

        guard remainingSeconds > 0 else {
            finishTimer()
            return
        }

        state = .running
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        startTicker()
    }

    func pause() {
        guard state == .running else {
            return
        }

        recalculateRemainingTime()
        stopTicker()
        endDate = nil
        state = .paused
    }

    func reset() {
        guard let selectedSong else {
            state = .idle
            remainingSeconds = 0
            stopTicker()
            return
        }

        stopTicker()
        endDate = nil
        remainingSeconds = selectedSong.totalSeconds
        state = .ready
    }

    func finishSong() {
        guard selectedSong != nil else {
            return
        }
        finishTimer()
    }

    func appDidBecomeActive() {
        recalculateRemainingTime()
    }

    /// Shifts remaining time by `delta` seconds (positive adds time). No-op when idle, finished, or no song.
    func adjustRemainingTime(bySeconds delta: Int) {
        guard selectedSong != nil else { return }
        switch state {
        case .idle, .finished:
            return
        case .running:
            guard let endDate else { return }
            let newRemaining = remainingSeconds + delta
            if newRemaining <= 0 {
                finishTimer()
                return
            }
            self.endDate = endDate.addingTimeInterval(TimeInterval(delta))
            remainingSeconds = newRemaining
        case .ready, .paused:
            let newRemaining = remainingSeconds + delta
            if newRemaining <= 0 {
                finishTimer()
                return
            }
            remainingSeconds = newRemaining
        }
    }
}

private extension SongTimerViewModel {
    func startTicker() {
        stopTicker()
        tickerTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                await MainActor.run {
                    self.recalculateRemainingTime()
                }
            }
        }
    }

    func stopTicker() {
        tickerTask?.cancel()
        tickerTask = nil
    }

    func recalculateRemainingTime() {
        guard let endDate, state == .running else {
            return
        }

        let remaining = Int(ceil(endDate.timeIntervalSinceNow))
        if remaining <= 0 {
            finishTimer()
        } else {
            remainingSeconds = remaining
        }
    }

    func finishTimer() {
        stopTicker()
        endDate = nil
        remainingSeconds = 0
        state = .finished
        hapticsManager.notifySuccess()
    }
}
