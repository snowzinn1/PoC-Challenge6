import Foundation

/// Fronteira entre a PoC e o "servidor".
/// Na PoC usamos o MockCheckInRepository (dados locais).
/// No STEMP real, basta uma segunda implementação que chame o WebService:
///   - hasCheckedInToday()  -> WebService.fetchCalendar
///   - registerPresence()   -> RegistrationViewModel.registerEvent / WebService.postRecord
protocol CheckInRepository {
    /// nil = não foi possível saber (ex.: sem rede)
    func hasCheckedInToday() async -> Bool?
    func registerPresence(tagID: String) async throws -> CheckInRecord
    func history() async -> [CheckInRecord]
    /// Apenas para testes da PoC
    func reset() async
}

/// Simula o servidor guardando os registros localmente, com um pequeno atraso de rede.
final class MockCheckInRepository: CheckInRepository {
    private let key = "poc.checkin.records"
    private let latency: Duration = .milliseconds(700)

    func hasCheckedInToday() async -> Bool? {
        try? await Task.sleep(for: latency)
        return load().contains { Calendar.current.isDateInToday($0.date) }
    }

    func registerPresence(tagID: String) async throws -> CheckInRecord {
        try? await Task.sleep(for: latency)
        let record = CheckInRecord(id: UUID(), date: Date(), tagID: tagID)
        save([record] + load())
        return record
    }

    func history() async -> [CheckInRecord] { load() }

    func reset() async { UserDefaults.standard.removeObject(forKey: key) }

    private func load() -> [CheckInRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([CheckInRecord].self, from: data) else { return [] }
        return records
    }

    private func save(_ records: [CheckInRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
