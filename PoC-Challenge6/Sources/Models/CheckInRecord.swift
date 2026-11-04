import Foundation

/// Um registro de ponto: presença (slider ou NFC) ou falta justificada.
struct CheckInRecord: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case presence, absence }
    enum Origin: String, Codable { case nfc, nfcQuick, slider }

    let id: UUID
    /// Presença: o instante do registro. Falta: o dia justificado (início do dia).
    let date: Date
    let kind: Kind
    var origin: Origin? = nil
    /// Local lido na etiqueta (ex.: "sala-01"). Só existe no fluxo NFC.
    var tagID: String? = nil
    /// true quando o aluno confirmou o registro mesmo fora da academy (fluxo do slider)
    var outsideAcademy: Bool = false
    var justification: String? = nil
}
