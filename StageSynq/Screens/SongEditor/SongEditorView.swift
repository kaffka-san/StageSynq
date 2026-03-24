import SwiftUI

struct SongEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SongEditorViewModel
    let onSave: (String, Int, Int, Int, String) -> Bool

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

                Section("songEditor.section.notes".localized) {
                    TextField("songEditor.notes.placeholder".localized, text: $viewModel.notes, axis: .vertical)
                        .lineLimit(4...10)
                }

                Section("songEditor.section.color".localized) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                        spacing: 12
                    ) {
                        ForEach(0..<SongCardPalette.count, id: \.self) { index in
                            Button {
                                viewModel.cardColorIndex = index
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(SongCardPalette.swiftUIColor(at: index))
                                        .frame(width: 40, height: 40)
                                    if viewModel.cardColorIndex == index {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                String(format: "songEditor.color.accessibility".localized, index + 1)
                            )
                        }
                    }
                }

                if let validationMessage = viewModel.validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .listSectionSeparator(.hidden)
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
                        if onSave(viewModel.name, viewModel.minutes, viewModel.seconds, viewModel.cardColorIndex, viewModel.notes) {
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
        onSave: { _, _, _, _, _ in true }
    )
}

#Preview("Edit") {
    SongEditorView(
        viewModel: SongEditorViewModel(
            mode: .edit(songID: UUID()),
            song: Song(name: "Finale", durationMinutes: 3, durationSeconds: 15, order: 0)
        ),
        onSave: { _, _, _, _, _ in true }
    )
}
