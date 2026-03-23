import UIKit

protocol HapticsManaging {
    func notifySuccess()
}

struct DefaultHapticsManager: HapticsManaging {
    func notifySuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
