//
//  HomeView.swift
// HomeView
//
//  Created by Guilherme Alves de Souza on 28/10/26.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AttendanceStore
    @EnvironmentObject var coordinator: NFCCheckInCoordinator

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        coordinator.start()
                    } label: {
                        Label("Bater ponto com NFC", systemImage: "wave.3.right.circle.fill")
                    }
                    .disabled(coordinator.isRunning)
                } footer: {
                    Text("Ou segure o Action Button do iPhone para disparar o atalho.")
                }

                Section("Registros") {
                    if store.records.isEmpty {
                        Text("Nenhum registro ainda.").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.records) { record in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                Text(record.tagID).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ponto NFC")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Limpar registros (PoC)", role: .destructive) {
                            Task { await store.debugReset() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: store.todayRecord == nil ? "clock.badge.questionmark" : "checkmark.seal.fill")
                .font(.system(size: 34))
                .foregroundStyle(store.todayRecord == nil ? Color.orange : Color.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.todayRecord == nil ? "Sem registro hoje" : "Presença registrada")
                    .font(.headline)
                if let record = store.todayRecord {
                    Text(record.date.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Aproxime o iPhone da etiqueta").foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    let store = AttendanceStore()
    HomeView()
        .environmentObject(AttendanceStore())
        .environmentObject(NFCCheckInCoordinator(store: store))
}
