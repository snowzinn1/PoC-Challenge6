//
//  CheckInNotificationManager.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 09/11/26.
//

import Foundation
import UserNotifications
import Combine

// Gerenciador responsável por solicitar permissões e agendar os lembretes de ponto.
@MainActor
final class CheckInNotificationManager: ObservableObject {
    static let shared = CheckInNotificationManager()

    // Indica se o usuário já autorizou o envio de notificações.
    @Published var isAuthorized: Bool = false

    private init() {
        checkAuthorizationStatus()
    }

    // Verifica o status atual da permissão no sistema.
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    // Solicita permissão ao usuário para enviar notificações.
    // Caso autorizado, já agenda os disparos diários automaticamente.
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                self.isAuthorized = granted
                if granted {
                    self.scheduleDailyReminders()
                }
                completion(granted)
            }
        }
    }

    func scheduleDailyReminders() {
        let center = UNUserNotificationCenter.current()

        // Remove notificações anteriores para evitar duplicidade
        let identifiers = [ "checkin-reminder-1345", "checkin-reminder-1350", "checkin-reminder-1355"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        // Lista de lembretes estruturados por horário e mensagem
        let reminders: [(hour: Int, minute: Int, id: String, body: String)] = [
            (13, 45, "checkin-reminder-1345", "Faltam 15 minutos para o tempo limite de registro de ponto."),
            (13, 50, "checkin-reminder-1350", "Faltam 10 minutos para o tempo limite de registro de ponto."),
            (13, 55, "checkin-reminder-1355", "Faltam 5 minutos para o tempo limite de registro de ponto!")
        ]

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = "Atenção ao Ponto"
            content.body = reminder.body
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute

            // Trigger para repetir todos os dias no horário especificado
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(
                identifier: reminder.id,
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Erro ao agendar notificação \(reminder.id): \(error.localizedDescription)")
                }
            }
        }
    }
}
