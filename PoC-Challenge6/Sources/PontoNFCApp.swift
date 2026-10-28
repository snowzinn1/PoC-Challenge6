import SwiftUI

@main
struct PontoNFCApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: AttendanceStore
    @StateObject private var coordinator: NFCCheckInCoordinator
    @ObservedObject private var launchRequest = NFCLaunchRequest.shared

    init() {
        let store = AttendanceStore()
        _store = StateObject(wrappedValue: store)
        _coordinator = StateObject(wrappedValue: NFCCheckInCoordinator(store: store))
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(coordinator)
                .overlay { CheckInOverlay(coordinator: coordinator) }
                // O Intent só deixa um aviso. Quem inicia o NFC é o app, quando já está ativo.
                // Observamos 3 eventos porque a ordem varia entre abertura a frio e app já aberto.
                .task { consumeNFCRequestIfReady() }
                .onChange(of: scenePhase) { _, _ in consumeNFCRequestIfReady() }
                .onChange(of: launchRequest.isPending) { _, _ in consumeNFCRequestIfReady() }
        }
    }

    private func consumeNFCRequestIfReady() {
        guard scenePhase == .active, launchRequest.isPending else { return }
        launchRequest.isPending = false
        Task {
            // Pequena folga para o app terminar de ficar ativo (ajustável)
            try? await Task.sleep(for: .milliseconds(350))
            coordinator.start()
        }
    }
}
