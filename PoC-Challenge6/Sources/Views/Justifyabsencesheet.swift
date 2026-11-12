//
//  Justifyabsencesheet.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import SwiftUI

/// Justificar falta: sempre dentro do app (exige um motivo) e confirmada com Face ID.
struct JustifyAbsenceSheet: View {
    let date: Date

    @EnvironmentObject var coordinator: NFCCheckInCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var reason: Reason = .health
    @State private var details = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private var dayText: String {
        date.formatted(.dateTime.day().month(.wide))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Motivo da falta em \(dayText)") {
                    Picker("Motivo", selection: $reason) {
                        ForEach(Reason.allCases) { Text($0.rawValue).tag($0) }
                    }
                    TextField("Detalhes (opcional)", text: $details, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }

                Section {
                    Button {
                        Task { await send() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending { ProgressView() } else { Text("Confirmar com Face ID").bold() }
                            Spacer()
                        }
                    }
                    .disabled(isSending)
                }
            }
            .navigationTitle("Justificar falta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func send() async {
        isSending = true
        errorMessage = nil
        let text = details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? reason.rawValue
            : "\(reason.rawValue): \(details)"

        if let error = await coordinator.submitAbsence(for: date, reason: text) {
            errorMessage = error
            isSending = false
        } else {
            dismiss()
        }
    }
}
