//
//  NFCCheckInCoordinator.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 28/10/26.
//


import SwiftUI
import Combine
/// Maestro do fluxo: etiqueta -> servidor -> Face ID -> registro.
/// Cada etapa é um Step, que a tela (CheckInOverlay) usa para se desenhar.
@MainActor
final class NFCCheckInCoordinator: ObservableObject {

    enum Step: Equatable {
        case idle
        case reading
        case checkingServer
        case authenticating
        case registering
        case success(Date)
        case failed(String)
    }

    /// Formato gravado nas etiquetas: "stemp:checkin:<local>"  (ex.: stemp:checkin:sala-01)
    static let tagPrefix = "stemp:checkin:"

    @Published private(set) var step: Step = .idle

    private let reader = NFCReader()
    private let store: AttendanceStore

    init(store: AttendanceStore) {
        self.store = store
    }

    var isRunning: Bool {
        switch step {
        case .idle, .success, .failed: return false
        default: return true
        }
    }

    func start() {
        guard !isRunning else { return }
        step = .reading

        reader.onRead    = { [weak self] value in self?.handleTag(value) }
        reader.onFailure = { [weak self] message in self?.step = .failed(message) }
        reader.onCancel  = { [weak self] in self?.step = .idle }
        reader.begin()
    }

    func dismiss() {
        if !isRunning { step = .idle }
    }

    private func handleTag(_ value: String) {
        guard value.hasPrefix(Self.tagPrefix) else {
            step = .failed("Etiqueta não reconhecida.")
            return
        }
        let tagID = String(value.dropFirst(Self.tagPrefix.count))
        Task { await runChain(tagID: tagID) }
    }

    private func runChain(tagID: String) async {
        // 1) O servidor é a fonte da verdade (consultamos antes de pedir Face ID)
        step = .checkingServer
        if await store.alreadyCheckedInToday() == true {
            step = .failed("Você já registrou o ponto hoje.")
            return
        }

        // 2) Face ID
        step = .authenticating
        let ok = await LocalAuthService.authorize(reason: "Confirme sua identidade para registrar o ponto")
        guard ok else {
            step = .failed("Face ID não confirmado.")
            return
        }

        // 3) Registro (a etiqueta é a prova de presença, por isso não consultamos o beacon)
        step = .registering
        do {
            try await store.registerPresence(tagID: tagID)
            step = .success(Date())
        } catch {
            step = .failed("Não foi possível registrar o ponto.")
        }
    }
}
