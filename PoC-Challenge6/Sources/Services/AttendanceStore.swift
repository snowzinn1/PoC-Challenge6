//
//  AttendanceStore.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 28/10/26.
//

import SwiftUI
import Combine

/// Um dia da semana exibido nos cards de "Registros".
struct DayCell: Identifiable, Equatable {
    enum State: Equatable {
        case present(Date)               // bateu o ponto (horário)
        case absent(justified: Bool)     // falta (justificada ou não)
        case today                       // hoje, ainda sem registro
        case future                      // dia que ainda não chegou
    }

    let date: Date
    let state: State
    var id: Date { date }
    var isToday: Bool { Calendar.current.isDateInToday(date) }

    /// Dias em que o aluno ainda pode justificar a falta
    var canJustify: Bool {
        switch state {
        case .absent(let justified): return !justified
        case .today:                 return true
        default:                     return false
        }
    }
}

/// Estado de presença exibido na tela. Fala com o "servidor" apenas via CheckInRepository.
@MainActor
final class AttendanceStore: ObservableObject {
    @Published private(set) var records: [CheckInRecord] = []
    private let repository: CheckInRepository

    init(repository: CheckInRepository = MockCheckInRepository()) {
        self.repository = repository
        Task { await refresh() }
    }

    // MARK: - Leitura

    var todayPresence: CheckInRecord? {
        records.first { $0.kind == .presence && Calendar.current.isDateInToday($0.date) }
    }

    /// Segunda a sexta da semana atual.
    /// Regra: dia passado sem presença = falta; com justificativa = falta justificada.
    var weekDays: [DayCell] {
        var cal = Calendar.current
        cal.firstWeekday = 2 // segunda-feira
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        let todayStart = cal.startOfDay(for: Date())

        return (0..<5).compactMap { offset -> DayCell? in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let entries = records.filter { cal.isDate($0.date, inSameDayAs: day) }

            let state: DayCell.State
            if let presence = entries.first(where: { $0.kind == .presence }) {
                state = .present(presence.date)
            } else if entries.contains(where: { $0.kind == .absence }) {
                state = .absent(justified: true)
            } else if day < todayStart {
                state = .absent(justified: false)
            } else if day == todayStart {
                state = .today
            } else {
                state = .future
            }
            return DayCell(date: day, state: state)
        }
    }

    // MARK: - Ações

    func refresh() async { records = await repository.history() }

    func alreadyCheckedInToday() async -> Bool? { await repository.hasCheckedInToday() }

    func registerPresence(origin: CheckInRecord.Origin, tagID: String?, outsideAcademy: Bool) async throws {
        _ = try await repository.registerPresence(origin: origin, tagID: tagID, outsideAcademy: outsideAcademy)
        await refresh()
    }

    func registerAbsence(date: Date, reason: String) async throws {
        _ = try await repository.registerAbsence(date: date, reason: reason)
        await refresh()
    }

    func debugReset() async {
        await repository.reset()
        await refresh()
    }
}
