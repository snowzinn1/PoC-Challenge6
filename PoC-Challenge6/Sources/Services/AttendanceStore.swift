import SwiftUI

/// Estado de presença exibido na tela. Fala com o "servidor" apenas via CheckInRepository.
@MainActor
final class AttendanceStore: ObservableObject {
    @Published private(set) var records: [CheckInRecord] = []
    private let repository: CheckInRepository

    init(repository: CheckInRepository = MockCheckInRepository()) {
        self.repository = repository
        Task { await refresh() }
    }

    var todayRecord: CheckInRecord? {
        records.first { Calendar.current.isDateInToday($0.date) }
    }

    func refresh() async { records = await repository.history() }

    func alreadyCheckedInToday() async -> Bool? { await repository.hasCheckedInToday() }

    func registerPresence(tagID: String) async throws {
        _ = try await repository.registerPresence(tagID: tagID)
        await refresh()
    }

    func debugReset() async {
        await repository.reset()
        await refresh()
    }
}
