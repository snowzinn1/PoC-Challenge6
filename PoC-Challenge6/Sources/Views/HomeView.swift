//
//  HomeView.swift
// PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 28/10/26.
//

import SwiftUI
 
/// Tela "Bate o ponto" (design dark/light via cores semânticas).
struct HomeView: View {
    @EnvironmentObject var store: AttendanceStore
    @EnvironmentObject var coordinator: NFCCheckInCoordinator
 
    @State private var showAllRecords = false
    @State private var absenceTarget: AbsenceTarget?
 
    // PoC: simula o beacon (no STEMP real vem do BeaconManager)
    @AppStorage(MockPresenceValidator.simulateOutsideKey) private var simulateOutside = false
 
    struct AbsenceTarget: Identifiable {
        let date: Date
        var id: Date { date }
    }
 
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                statusBlock
 
                PresenceSlider(
                    isLocked: store.todayPresence != nil,
                    lockedText: lockedText,
                    onComplete: { await coordinator.runSliderCheckIn() }
                )
 
                Text("Para bater o ponto **use o slider** ou **segure o Action Button do iPhone** para disparar o atalho.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
 
                recordsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAllRecords) { AllRecordsView() }
        .sheet(item: $absenceTarget) { target in
            JustifyAbsenceSheet(date: target.date)
        }
    }
 
    // MARK: - Partes
 
    private var header: some View {
        HStack {
            Text("Bate o ponto")
                .font(.system(size: 38, weight: .bold))
            Spacer()
            // Menu de debug da PoC (remover na versão final)
            Menu {
                Toggle("Simular fora da academy", isOn: $simulateOutside)
                Button("Limpar registros", role: .destructive) {
                    Task { await store.debugReset() }
                }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3).foregroundStyle(.secondary)
            }
        }
    }
 
    private var statusBlock: some View {
        VStack(spacing: 18) {
            if let presence = store.todayPresence {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 120))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                Text("Ponto batido às \(presence.date.formatted(date: .omitted, time: .shortened))")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 120))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
                Text("Você ainda não bateu o ponto.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 260)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
 
    private var lockedText: String {
        if let presence = store.todayPresence {
            return "Presença registrada às \(presence.date.formatted(date: .omitted, time: .shortened))"
        }
        return "Presença registrada"
    }
 
    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Registros").font(.title.bold())
                Spacer()
                Button("Ver tudo") { showAllRecords = true }
                    .foregroundStyle(.orange)
            }
 
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.weekDays) { day in
                        Button {
                            if day.canJustify { absenceTarget = AbsenceTarget(date: day.date) }
                        } label: {
                            DayCard(day: day)
                        }
                        .buttonStyle(.plain)
                        .disabled(!day.canJustify)
                    }
                }
                .padding(14)
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24))
 
            Text("Toque em um dia com falta (ou em hoje) para justificar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
 
//#Preview {
//    HomeView(store: <#T##AttendanceStore#>, coordinator: <#T##NFCCheckInCoordinator#>, showAllRecords: <#T##arg#>, absenceTarget: <#T##AbsenceTarget?#>, simulateOutside: <#T##arg#>)
//}
