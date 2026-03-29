import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppSettings.fontSizePresetKey) private var fontSizePresetRaw = AppSettings.defaultFontSizePreset
    @AppStorage(AppSettings.timerUrgentSecondsKey) private var timerUrgentSeconds = AppSettings.defaultTimerUrgentSeconds
    @AppStorage(AppSettings.timerAdjustStepKey) private var timerAdjustStep = AppSettings.defaultTimerAdjustStep

    private let adjustStepChoices = [5, 10, 15, 30, 45, 60]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("settings.fontSize.title".localized, selection: $fontSizePresetRaw) {
                        ForEach(AppFontSizePreset.allCases) { preset in
                            Text(preset.localizationKey.localized).tag(preset.rawValue)
                        }
                    }
                } footer: {
                    Text("settings.fontSize.footer".localized)
                }

                Section {
                    Stepper(
                        value: $timerUrgentSeconds,
                        in: 5...180,
                        step: 5
                    ) {
                        Text(
                            String(
                                format: "settings.timerUrgentSeconds.value".localized,
                                timerUrgentSeconds
                            )
                        )
                    }
                } header: {
                    Text("settings.timerUrgentSeconds.title".localized)
                } footer: {
                    Text("settings.timerUrgentSeconds.footer".localized)
                }

                Section {
                    Picker("settings.timerAdjustStep.title".localized, selection: $timerAdjustStep) {
                        ForEach(adjustStepChoices, id: \.self) { value in
                            Text(
                                String(format: "settings.timerAdjustStep.seconds".localized, value)
                            )
                            .tag(value)
                        }
                    }
                } footer: {
                    Text("settings.timerAdjustStep.footer".localized)
                }
            }
            .scrollContentBackground(.hidden)
            .background(StageSyncStyle.background.ignoresSafeArea())
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(StageSyncStyle.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(StageSyncStyle.accent)
        .onAppear {
            if !adjustStepChoices.contains(timerAdjustStep) {
                timerAdjustStep = AppSettings.defaultTimerAdjustStep
            }
        }
    }
}

#Preview {
    SettingsView()
}
