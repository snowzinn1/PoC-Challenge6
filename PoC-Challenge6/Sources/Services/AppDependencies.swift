//
//  AppDependencies.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import Foundation

/// Pontos únicos de acesso ao "servidor" e à validação de proximidade.
/// O app (tela) e os App Intents usam as MESMAS instâncias/fontes, porque o Intent do modo rápido
/// pode rodar sem a tela existir. No STEMP real, troque aqui pelas implementações com WebService e BeaconManager.
@MainActor
enum AppDependencies {
    static let repository: any CheckInRepository = MockCheckInRepository()
    static let validator: any PresenceValidator = MockPresenceValidator()
}
