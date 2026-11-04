//
//  NFCCheckInCoordinator.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 28/10/26.
//

import SwiftUI
import Combine

/// Maestro dos dois caminhos de registro, com as mesmas regras:
///
///  NFC (Action Button):  etiqueta -> servidor -> Face ID -> registro   (a etiqueta é a prova de presença)
///  Slider (convencional): servidor -> Face ID -> validação de proximidade -> registro
///  Falta: Face ID -> justificativa (sempre dentro do app)
///
/// Cada etapa é um Step, que a tela (CheckInOverlay) usa para se desenhar.
@MainActor
final class NFCCheckInCoordinator: ObservableObject {

    enum Step: Equatable {
        case idle
        case reading                    // folha do NFC (do sistema)
        case checkingServer
        case authenticating             // Face ID (do sistema)
        case validatingLocation
        case confirmingOutsideAcademy   // aguardando decisão do aluno
        case registering
        case success(Date)
        case absenceSent
        case failed(String)
    }

    /// Formato gravado nas etiquetas: "stemp:checkin:<local>"  (ex.: stemp:checkin:sala-01)
    static let tagPrefix = "stemp:checkin:"

    @Published private(set) var step: Step = .idle

    private let reader = NFCReader()
    private let store: AttendanceStore
    private let validator: PresenceValidator
    private var outsideDecision: CheckedContinuation<Bool, Never>?

    init(store: AttendanceStore, validator: PresenceValidator = MockPresenceValidator()) {
        self.store = store
        self.validator = validator
    }

    var isRunning: Bool {
        switch step {
        case .idle, .success, .absenceSent, .failed: return false
        default: return true
        }
    }

    // MARK: - Caminho NFC (Action Button)

    func startNFC() {
        guard !isRunning else { return }

        // Atalho rápido: o cooldown já está visível, não vale abrir a leitura à toa
        if store.todayPresence != nil {
            step = .failed("Você já registrou o ponto hoje.")
            return
        }

        step = .reading
        reader.onRead    = { [weak self] value in self?.handleTag(value) }
        reader.onFailure = { [weak self] message in self?.step = .failed(message) }
        reader.onCancel  = { [weak self] in self?.step = .idle }
        reader.begin()
    }

    private func handleTag(_ value: String) {
        guard value.hasPrefix(Self.tagPrefix) else {
            step = .failed("Etiqueta não reconhecida.")
            return
        }
        let tagID = String(value.dropFirst(Self.tagPrefix.count))
        Task { await runChain(origin: .nfc, tagID: tagID) }
    }

    // MARK: - Caminho do slider

    /// Retorna true se o ponto foi registrado (o slider usa isso para travar ou voltar ao início).
    func runSliderCheckIn() async -> Bool {
        guard !isRunning else { return false }
        return await runChain(origin: .slider, tagID: nil)
    }

    // MARK: - Justificar falta (sempre no app, com Face ID)

    /// Retorna nil em caso de sucesso, ou a mensagem de erro para a folha de justificativa.
    func submitAbsence(for date: Date, reason: String) async -> String? {
        guard !isRunning else { return "Aguarde o registro em andamento." }

        let ok = await LocalAuthService.authorize(reason: "Confirme sua identidade para justificar a falta")
        guard ok else { return "Face ID não confirmado." }

        do {
            try await store.registerAbsence(date: date, reason: reason)
            step = .absenceSent
            return nil
        } catch {
            return "Não foi possível enviar a justificativa."
        }
    }

    // MARK: - Decisões do overlay

    func confirmOutsideAcademy(_ accepted: Bool) {
        outsideDecision?.resume(returning: accepted)
        outsideDecision = nil
    }

    func dismiss() {
        if !isRunning { step = .idle }
    }

    // MARK: - Cadeia comum de registro

    @discardableResult
    private func runChain(origin: CheckInRecord.Origin, tagID: String?) async -> Bool {
        // 1) O servidor é a fonte da verdade (consultamos antes de pedir Face ID)
        step = .checkingServer
        if await store.alreadyCheckedInToday() == true {
            step = .failed("Você já registrou o ponto hoje.")
            return false
        }

        // 2) Face ID
        step = .authenticating
        let ok = await LocalAuthService.authorize(reason: "Confirme sua identidade para registrar o ponto")
        guard ok else {
            step = .failed("Face ID não confirmado.")
            return false
        }

        // 3) Proximidade: só no slider. No NFC a etiqueta colada ao beacon já é a prova.
        var outside = false
        if origin == .slider {
            step = .validatingLocation
            if await validator.isInsideAcademy() == false {
                step = .confirmingOutsideAcademy
                let accepted = await withCheckedContinuation { outsideDecision = $0 }
                guard accepted else {
                    step = .idle
                    return false
                }
                outside = true
            }
        }

        // 4) Registro
        step = .registering
        do {
            try await store.registerPresence(origin: origin, tagID: tagID, outsideAcademy: outside)
            step = .success(Date())
            return true
        } catch {
            step = .failed("Não foi possível registrar o ponto.")
            return false
        }
    }
}
