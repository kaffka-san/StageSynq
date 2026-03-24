import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class FlashlightController {
    private(set) var isOn: Bool = false

    func toggle() {
        Task { @MainActor in
            guard await ensureCameraAuthorized() else {
                return
            }
            applyTorchToggle()
        }
    }

    func turnOffIfNeeded() {
        guard isOn else {
            return
        }
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            isOn = false
            return
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.torchMode = .off
            isOn = false
        } catch {
            isOn = false
        }
    }

    private func ensureCameraAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    private func applyTorchToggle() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            isOn = false
            return
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if device.torchMode == .on {
                device.torchMode = .off
                isOn = false
            } else {
                let level = min(Float(1), AVCaptureDevice.maxAvailableTorchLevel)
                try device.setTorchModeOn(level: level)
                isOn = true
            }
        } catch {
            isOn = false
        }
    }
}
