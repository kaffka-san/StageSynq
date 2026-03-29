import SwiftUI

struct AppCoordinatorView: View {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.fontSizePresetKey) private var fontSizePresetRaw = AppSettings.defaultFontSizePreset

    private var fontSizePreset: AppFontSizePreset {
        AppFontSizePreset(rawValue: fontSizePresetRaw) ?? .standard
    }

    var body: some View {
        @Bindable var bindableCoordinator = coordinator

        NavigationStack(path: $bindableCoordinator.navigationPath) {
            PlaylistListView(viewModel: coordinator.listViewModel)
                .navigationDestination(for: AppCoordinator.Route.self) { route in
                    coordinator.destination(for: route)
                }
        }
        .environment(\.dynamicTypeSize, fontSizePreset.dynamicTypeSize)
        .preferredColorScheme(.dark)
        .toolbarBackground(StageSyncStyle.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                coordinator.timerViewModel.appDidBecomeActive()
            }
        }
    }
}

#Preview {
    AppCoordinatorView()
}
