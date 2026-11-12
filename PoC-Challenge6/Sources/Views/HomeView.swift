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

    @State private var showOverview = false
    @State private var absenceTarget: AbsenceTarget?

    private let eventRepository: EventRepository = MockEventRepository()
    private let checkInRepository: CheckInRepository = MockCheckInRepository()

    // PoC: simula o beacon (no STEMP real vem do BeaconManager)
    @AppStorage(MockPresenceValidator.simulateOutsideKey) private var simulateOutside = false

    struct AbsenceTarget: Identifiable {
        let date: Date
        var id: Date { date }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                header
                Spacer()

                monthSection
                Spacer()

                
                TodayEventsSection(repository: eventRepository)

                Spacer()
                VStack(spacing: 16) {
                    nfcButton

                    PresenceSlider(
                        isLocked: store.todayPresence != nil,
                        lockedText: "Ponto de hoje registrado!",
                        onComplete: { await coordinator.runSliderCheckIn() }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationDestination(isPresented: $showOverview) {
            AttendanceOverviewView(year: currentYear, repository: checkInRepository)
        }
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
                Image(systemName: "ellipsis.circle")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var monthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "LLLL"
        return f.string(from: Date()).capitalized
    }

    private var monthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(monthName)
                    .font(.title3)
                Spacer()
                Button {
                    showOverview = true
                } label: {
                    Text("ver mais")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            WeeklyAttendanceView(store: store)
        }
    }

    private var nfcButton: some View {
        Button {
            coordinator.startNFC()
        } label: {
            HStack {
                Text("Habilitar registro com NFC")
                    .font(.body)
                Spacer()
                Image(systemName: "dot.radiowaves.right")
                    .font(.system(size: 26, weight: .semibold))
            }
            .foregroundStyle(Color.blue)
            .padding(.horizontal, 24)
            .frame(height: 52)
            .overlay(
                Capsule().stroke(Color.blue, lineWidth: 1.5)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("HomeView Preview") {
    let store = AttendanceStore()
    return NavigationStack {
        HomeView()
    }
    .environmentObject(store)
    .environmentObject(NFCCheckInCoordinator(store: store))
}
