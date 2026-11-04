//
//  CheckInOverlay.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 28/10/26.
//

import SwiftUI
import UIKit

/// Cobre a tela durante as etapas do registro (a folha do NFC e o Face ID são do sistema).
/// Mostra progresso, a confirmação de "fora da academy", o check animado de sucesso (com vibração) ou o erro.
struct CheckInOverlay: View {
    @ObservedObject var coordinator: NFCCheckInCoordinator

    private enum Display {
        case progress(String)
        case confirmOutside
        case success(title: String, detail: String?)
        case failure(String)
    }

    private var display: Display? {
        switch coordinator.step {
        case .idle, .reading:           return nil
        case .checkingServer:           return .progress("Verificando seu registro…")
        case .authenticating:           return .progress("Confirme com o Face ID")
        case .validatingLocation:       return .progress("Verificando sua localização…")
        case .confirmingOutsideAcademy: return .confirmOutside
        case .registering:              return .progress("Registrando presença…")
        case .success(let date):
            return .success(title: "Ponto registrado",
                            detail: date.formatted(date: .omitted, time: .shortened))
        case .absenceSent:
            return .success(title: "Falta justificada", detail: nil)
        case .failed(let message):      return .failure(message)
        }
    }

    var body: some View {
        ZStack {
            if let display {
                Color.black.opacity(0.35).ignoresSafeArea().transition(.opacity)
                card(for: display).transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: coordinator.step)
        .task(id: coordinator.step) { await react(to: coordinator.step) }
    }

    @ViewBuilder
    private func card(for display: Display) -> some View {
        VStack(spacing: 16) {
            switch display {
            case .progress(let text):
                ProgressView().scaleEffect(1.6).padding(.top, 8)
                Text(text).font(.headline).multilineTextAlignment(.center)

            case .confirmOutside:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60)).foregroundStyle(.orange)
                Text("Você parece estar fora da academy.").font(.headline).multilineTextAlignment(.center)
                Text("Registrar o ponto mesmo assim? Ele será marcado como fora da academy.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Registrar mesmo assim") { coordinator.confirmOutsideAcademy(true) }
                    .buttonStyle(.borderedProminent)
                Button("Cancelar") { coordinator.confirmOutsideAcademy(false) }
                    .buttonStyle(.bordered)

            case .success(let title, let detail):
                SuccessMark()
                Text(title).font(.title3.bold())
                if let detail { Text(detail).foregroundStyle(.secondary) }

            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 70)).foregroundStyle(.red)
                Text(message).font(.headline).multilineTextAlignment(.center)
                Button("Fechar") { coordinator.dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
    }

    private func react(to step: NFCCheckInCoordinator.Step) async {
        switch step {
        case .success, .absenceSent:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .seconds(2.2))
            if !Task.isCancelled { coordinator.dismiss() }
        case .failed:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        default:
            break
        }
    }
}

private struct SuccessMark: View {
    @State private var appeared = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 84))
            .foregroundStyle(.green)
            .scaleEffect(appeared ? 1 : 0.4)
            .opacity(appeared ? 1 : 0)
            .symbolEffect(.bounce, value: appeared)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { appeared = true }
            }
    }
}
