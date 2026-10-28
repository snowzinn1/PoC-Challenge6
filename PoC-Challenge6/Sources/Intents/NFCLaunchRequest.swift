import Foundation
import Combine

/// Aviso compartilhado entre o App Intent e o app:
/// o Intent marca "há uma leitura pendente" e o app inicia o NFC quando estiver ativo.
@MainActor
final class NFCLaunchRequest: ObservableObject {
    static let shared = NFCLaunchRequest()
    @Published var isPending = false
}
