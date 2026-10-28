import AppIntents

struct BaterPontoNFCIntent: AppIntent {
    static let title: LocalizedStringResource = "Bater ponto com NFC"
    static let description = IntentDescription("Abre o app e lê a etiqueta NFC para registrar sua presença.")
    // Em versões novas do iOS esta propriedade pode gerar um aviso de depreciação; o comportamento é o mesmo.
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NFCLaunchRequest.shared.isPending = true
        return .result()
    }
}

/// Faz o atalho aparecer sozinho no app Atalhos (e disponível para o Action Button e a Siri).
/// A frase PRECISA conter \(.applicationName).
struct PontoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BaterPontoNFCIntent(),
            phrases: [
                "Bater ponto no \(.applicationName)",
                "Registrar presença no \(.applicationName)"
            ],
            shortTitle: "Bater ponto",
            systemImageName: "wave.3.right.circle"
        )
    }
}
