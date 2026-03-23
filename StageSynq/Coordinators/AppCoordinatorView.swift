import SwiftUI

struct AppCoordinatorView: View {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var bindableCoordinator = coordinator

        NavigationStack(path: $bindableCoordinator.navigationPath) {
            PlaylistListView(viewModel: coordinator.listViewModel)
                .navigationDestination(for: AppCoordinator.Route.self) { route in
                    coordinator.destination(for: route)
                }
        }
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
