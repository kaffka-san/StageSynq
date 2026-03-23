import SwiftUI

struct SongEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SongEditorViewModel
    let onSave: (String, Int, Int) -> Bool

    @State private var minutesInput: String = "0"
    @State private var secondsInput: String = "0"

    var body: some View {
        NavigationStack {
            Form {
                Section("songEditor.section.basic".localized) {
                    TextField("songEditor.name.placeholder".localized, text: $viewModel.name)
                }

                Section("songEditor.section.duration".localized) {
                    TextField("songEditor.minutes.placeholder".localized, text: $minutesInput)
                        .keyboardType(.numberPad)
                    TextField("songEditor.seconds.placeholder".localized, text: $secondsInput)
                        .keyboardType(.numberPad)
                }

                if let validationMessage = viewModel.validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .background(StageSyncStyle.background.ignoresSafeArea())
            .navigationTitle(viewModel.titleKey.localized)
            .toolbarBackground(StageSyncStyle.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save".localized) {
                        viewModel.updateMinutes(from: minutesInput)
                        viewModel.updateSeconds(from: secondsInput)
                        if onSave(viewModel.name, viewModel.minutes, viewModel.seconds) {
                            dismiss()
                        }
                    }
                }
            }
            .tint(StageSyncStyle.accent)
            .onAppear {
                minutesInput = String(viewModel.minutes)
                secondsInput = String(viewModel.seconds)
            }
        }
    }
}

#Preview("Add") {
    SongEditorView(
        viewModel: SongEditorViewModel(mode: .add),
        onSave: { _, _, _ in true }
    )
}

#Preview("Edit") {
    SongEditorView(
        viewModel: SongEditorViewModel(
            mode: .edit(songID: UUID()),
            song: Song(name: "Finale", durationMinutes: 3, durationSeconds: 15, order: 0)
        ),
        onSave: { _, _, _ in true }
    )
}
