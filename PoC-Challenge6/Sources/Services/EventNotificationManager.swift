//
//  EventNotificationManager.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 11/11/26.
//

import Foundation
import UserNotifications
import Combine

/// Agenda um aviso local 20 minutos antes de cada evento.
@MainActor
final class EventNotificationManager: ObservableObject {
    static let shared = EventNotificationManager()

    @Published var isAuthorized: Bool = false

    /// Quantos minutos antes do evento o aviso dispara.
    private let leadMinutes: Int = 20
    private let idPrefix: String = "event-reminder-"

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    /// Recria os lembretes de acordo com a lista atual de eventos (evita duplicidade).
    func scheduleReminders(for events: [AcademyEvent]) async {
        let center = UNUserNotificationCenter.current()

        // Remove os lembretes antigos de eventos
        let pending: [UNNotificationRequest] = await center.pendingNotificationRequests()
        let oldIDs: [String] = pending
            .map { $0.identifier }
            .filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        let settings: UNNotificationSettings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        for event in events {
            schedule(event, center: center)
        }
    }

    private func schedule(_ event: AcademyEvent, center: UNUserNotificationCenter) {
        let fireDate: Date = event.start.addingTimeInterval(TimeInterval(-leadMinutes * 60))
        guard fireDate > Date() else { return } // já passou, não agenda

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Faltam \(leadMinutes) minutos para sua entrega."
        content.sound = .default

        let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        let comps: DateComponents = Calendar.current.dateComponents(parts, from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(identifier: idPrefix + event.id.uuidString,
                                            content: content,
                                            trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Erro ao agendar lembrete \(event.id): \(error.localizedDescription)")
            }
        }
    }
}
