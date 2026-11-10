//
//  CheckInSuccessContent.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 09/11/26.
//

import SwiftUI

/// Conteúdo do card de sucesso: selo verde com confetes animados, título, mensagem e botão "Confirmar".
/// O fundo/arredondamento do card fica por conta de quem usa (o `CheckInOverlay` já aplica o material).
struct CheckInSuccessContent: View {
    let title: String
    var message: String? = nil
    /// `false` mostra só o selo, sem confetes (ex.: falta justificada).
    var celebrate: Bool = true
    var onConfirm: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if celebrate {
                    ConfettiBurst(active: appeared)
                }
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(.green)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
                    .symbolEffect(.bounce, value: appeared)
            }
            .frame(width: 220, height: 180)

            Text(title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            Button("Confirmar", action: onConfirm)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .padding(.top, 4)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { appeared = true }
        }
    }
}

// MARK: - Confetes

private struct ConfettiPiece: Identifiable {
    let id: Int
    let angle: Double      // graus; 0 = direita, positivo = sentido horário (eixo Y da tela aponta para baixo)
    let distance: CGFloat  // distância do centro do selo
    let size: CGSize
    let color: Color
    let rotation: Double   // rotação final em graus
    let drift: CGFloat     // quanto "flutua" para dentro/fora depois da explosão
    let duration: Double   // duração de um ciclo da flutuação
    let delay: Double      // atraso da explosão

    private static let orange = Color(red: 0.98, green: 0.60, blue: 0.25)
    private static let yellow = Color(red: 0.98, green: 0.80, blue: 0.26)
    private static let purple = Color(red: 0.75, green: 0.30, blue: 0.85)

    static let all: [ConfettiPiece] = [
        .init(id: 0, angle: -118, distance: 82, size: .init(width: 7,  height: 10), color: orange, rotation: 20,  drift: 4, duration: 1.3, delay: 0.00),
        .init(id: 1, angle: -61,  distance: 80, size: .init(width: 14, height: 7),  color: yellow, rotation: -35, drift: 5, duration: 1.6, delay: 0.04),
        .init(id: 2, angle: -162, distance: 84, size: .init(width: 8,  height: 5),  color: yellow, rotation: 0,   drift: 3, duration: 1.1, delay: 0.08),
        .init(id: 3, angle: -14,  distance: 76, size: .init(width: 7,  height: 8),  color: orange, rotation: 30,  drift: 4, duration: 1.8, delay: 0.02),
        .init(id: 4, angle: 156,  distance: 86, size: .init(width: 14, height: 7),  color: purple, rotation: 20,  drift: 5, duration: 1.5, delay: 0.06),
        .init(id: 5, angle: 38,   distance: 84, size: .init(width: 9,  height: 6),  color: purple, rotation: 35,  drift: 4, duration: 1.2, delay: 0.10),
        .init(id: 6, angle: 95,   distance: 76, size: .init(width: 8,  height: 6),  color: yellow, rotation: 35,  drift: 3, duration: 1.7, delay: 0.05),
    ]
}

private struct ConfettiBurst: View {
    let active: Bool

    var body: some View {
        ZStack {
            ForEach(ConfettiPiece.all) { piece in
                ConfettiPieceView(piece: piece, active: active)
            }
        }
    }
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let active: Bool

    @State private var floating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let radians = piece.angle * .pi / 180
        // explosão (active) + flutuação contínua (floating)
        let push = (active ? piece.distance : 0) + (floating ? piece.drift : -piece.drift)

        RoundedRectangle(cornerRadius: 1.5)
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(piece.rotation + (active ? 0 : -140) + (floating ? 30 : -30)))
            .offset(x: cos(radians) * push, y: sin(radians) * push)
            .scaleEffect(active ? 1 : 0.2)
            .opacity(active ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.55).delay(piece.delay), value: active)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: piece.duration).repeatForever(autoreverses: true),
                value: floating
            )
            .task {
                guard !reduceMotion else { return }
                try? await Task.sleep(for: .seconds(0.8)) // espera a explosão terminar
                floating = true
            }
    }
}

// MARK: - Preview

private struct SuccessPreviewCard: View {
    var body: some View {
        CheckInSuccessContent(title: "Ponto registrado", message: "Agora vai trabalhar!") {}
            .padding(28)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .padding()
    }
}

#Preview("Claro") {
    SuccessPreviewCard().preferredColorScheme(.light)
}

#Preview("Escuro") {
    SuccessPreviewCard().preferredColorScheme(.dark)
}
