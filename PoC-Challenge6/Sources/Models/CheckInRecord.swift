import Foundation

struct CheckInRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    /// Identificador do local lido na etiqueta (ex.: "sala-01")
    let tagID: String
}
