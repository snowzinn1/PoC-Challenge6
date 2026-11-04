//
//  QuickCheckIntent.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import AppIntents

/// MODO RÁPIDO: registra o ponto SEM abrir o app.
/// Uso: automação NFC do app Atalhos (uma automação por etiqueta, cada uma com o seu "Local da etiqueta").
///
/// Diferenças para o modo estrito (Action Button + Core NFC):
///  - não há folha do Core NFC: quem lê a etiqueta é o iOS, e o feedback é o diálogo deste Intent;
///  - o Intent não lê o conteúdo da etiqueta: o local vem do parâmetro fixo da automação;
///  - a autenticação vem da política abaixo (o iOS exige o aparelho desbloqueado).
struct QuickCheckInIntent: AppIntent {
    static let title: LocalizedStringResource = "Bater ponto rápido (NFC)"
    static let description = IntentDescription(
        "Registra a presença sem abrir o app. Use na automação NFC do Atalhos, uma por etiqueta."
    )
    static let openAppWhenRun: Bool = false
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    @Parameter(title: "Local da etiqueta", default: "sala-01")
    var localID: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let repository = AppDependencies.repository

        // 1) O servidor é a fonte da verdade (se a consulta falhar, o servidor ainda bloqueia duplicidade)
        if await repository.hasCheckedInToday() == true {
            return .result(dialog: "Você já registrou o ponto hoje.")
        }

        // 2) Mitigação: sem a folha do NFC, conferimos a proximidade; fora da academy pede confirmação
        var outside = false
        if await AppDependencies.validator.isInsideAcademy() == false {
            try await requestConfirmation(
                result: .result(dialog: "Você parece estar fora da academy. Registrar o ponto mesmo assim?")
            )
            outside = true
        }

        // 3) Registro
        let record = try await repository.registerPresence(origin: .nfcQuick, tagID: localID, outsideAcademy: outside)
        let time = record.date.formatted(date: .omitted, time: .shortened)
        return .result(dialog: "Ponto registrado às \(time).")
    }
}
