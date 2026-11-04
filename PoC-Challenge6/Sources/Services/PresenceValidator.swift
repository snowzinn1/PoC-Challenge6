//
//  PresenceValidator.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import Foundation

/// Validação de proximidade do fluxo do SLIDER (no fluxo NFC a etiqueta é a prova de presença).
/// No STEMP real isso é o BeaconManager.isInsideAcademy; aqui é simulado para a PoC.
protocol PresenceValidator {
    func isInsideAcademy() async -> Bool
}

struct MockPresenceValidator: PresenceValidator {
    /// Chave usada pelo menu de debug da tela ("Simular fora da academy")
    static let simulateOutsideKey = "poc.simulateOutside"

    func isInsideAcademy() async -> Bool {
        try? await Task.sleep(for: .milliseconds(500))
        return !UserDefaults.standard.bool(forKey: Self.simulateOutsideKey)
    }
}
