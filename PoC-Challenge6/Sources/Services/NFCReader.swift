import CoreNFC

/// Lê uma etiqueta NDEF de texto com Core NFC.
/// A folha com o check azul é do sistema: só controlamos o texto (alertMessage).
@MainActor
final class NFCReader: NSObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?

    var onRead: ((String) -> Void)?
    var onFailure: ((String) -> Void)?
    var onCancel: (() -> Void)?

    static var isAvailable: Bool { NFCNDEFReaderSession.readingAvailable }

    func begin() {
        guard Self.isAvailable else {
            onFailure?("Este aparelho não suporta leitura NFC.")
            return
        }
        let newSession = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
        newSession.alertMessage = "Aproxime o iPhone da etiqueta ao lado do beacon"
        session = newSession
        newSession.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate
    // Os callbacks chegam na fila principal (queue: .main), por isso assumeIsolated é seguro.

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        MainActor.assumeIsolated { handleDetected(session, messages) }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        MainActor.assumeIsolated { handleInvalidation(error) }
    }

    // MARK: - Tratamento

    private func handleDetected(_ session: NFCNDEFReaderSession, _ messages: [NFCNDEFMessage]) {
        guard let record = messages.first?.records.first else {
            session.alertMessage = "Etiqueta vazia"
            onFailure?("Etiqueta vazia.")
            return
        }
        let (text, _) = record.wellKnownTypeTextPayload()
        guard let value = text else {
            session.alertMessage = "Etiqueta não reconhecida"
            onFailure?("Etiqueta inválida.")
            return
        }
        // Este texto aparece junto do check azul quando a sessão encerra com sucesso
        session.alertMessage = "Etiqueta lida com sucesso"
        onRead?(value)
    }

    private func handleInvalidation(_ error: Error) {
        session = nil
        let code = (error as? NFCReaderError)?.code
        // Fim normal da sessão após a primeira leitura: não é erro
        if code == .readerSessionInvalidationErrorFirstNDEFTagRead { return }
        if code == .readerSessionInvalidationErrorUserCanceled { onCancel?(); return }
        onFailure?(error.localizedDescription)
    }
}
