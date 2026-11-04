//
//  AllRecordsView.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import SwiftUI

/// "Ver tudo": histórico completo, do mais recente para o mais antigo.
struct AllRecordsView: View {
    @EnvironmentObject var store: AttendanceStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if store.records.isEmpty {
                    Text("Nenhum registro ainda.").foregroundStyle(.secondary)
                } else {
                    ForEach(store.records) { RecordRow(record: $0) }
                }
            }
            .navigationTitle("Registros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

private struct RecordRow: View {
    let record: CheckInRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.kind == .presence ? "checkmark.circle.fill" : "doc.text.fill")
                .font(.title2)
                .foregroundStyle(record.kind == .presence ? Color.green : Color.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(whenText).font(.subheadline).foregroundStyle(.secondary)
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
                if record.outsideAcademy {
                    Text("Registrado fora da academy").font(.caption).foregroundStyle(.orange)
                }
            }
        }
    }

    private var title: String { record.kind == .presence ? "Presença" : "Falta justificada" }

    private var whenText: String {
        record.kind == .presence
            ? record.date.formatted(date: .abbreviated, time: .shortened)
            : record.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var detail: String? {
        switch record.kind {
        case .absence:
            return record.justification
        case .presence:
            switch record.origin {
            case .nfc:    return "NFC" + (record.tagID.map { " · \($0)" } ?? "")
            case .nfcQuick: return "NFC rápido" + (record.tagID.map { " · \($0)" } ?? "")
            case .slider: return "Slider"
            case nil:     return nil
            }
        }
    }
}
