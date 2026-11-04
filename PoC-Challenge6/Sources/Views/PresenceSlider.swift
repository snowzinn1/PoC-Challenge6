//
//  PresenceSlider.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import SwiftUI
import UIKit

/// Slider "deslize para bater o ponto".
/// - Deslizar até o fim chama onComplete (que faz servidor, Face ID, proximidade e registro).
/// - Se onComplete devolver false (Face ID negado, já registrado, cancelado...), o botão volta ao início.
/// - Com isLocked == true o slider vira o "cooldown" visual: ponto já batido hoje.
struct PresenceSlider: View {
    let isLocked: Bool
    let lockedText: String
    let onComplete: () async -> Bool

    @State private var offset: CGFloat = 0
    @State private var isBusy = false

    private let trackHeight: CGFloat = 64
    private let knobSize: CGFloat = 52
    private let inset: CGFloat = 6
    private let completionThreshold: CGFloat = 0.85

    var body: some View {
        GeometryReader { geo in
            let maxOffset = max(geo.size.width - knobSize - inset * 2, 1)

            ZStack(alignment: .leading) {
                Capsule().fill(Color(.secondarySystemBackground))

                if isLocked {
                    Capsule().fill(Color.green.opacity(0.18))
                    Text(lockedText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                } else {
                    Capsule()
                        .fill(Color.orange.opacity(0.25))
                        .frame(width: offset + knobSize + inset * 2)
                }

                Circle()
                    .fill(LinearGradient(colors: [Color(white: 0.80), Color(white: 0.42)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: knobSize, height: knobSize)
                    .overlay {
                        Image(systemName: isLocked ? "checkmark" : "chevron.right")
                            .font(.headline.bold())
                            .foregroundStyle(isLocked ? Color.white : Color.black.opacity(0.55))
                    }
                    .padding(.leading, inset)
                    .offset(x: isLocked ? maxOffset : offset)
                    .gesture(drag(maxOffset: maxOffset))
            }
        }
        .frame(height: trackHeight)
        .onChange(of: isLocked) { _, locked in
            if !locked { withAnimation(.spring) { offset = 0 } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isLocked ? lockedText : "Deslize para bater o ponto")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard !isLocked, !isBusy else { return }
            Task { _ = await onComplete() }
        }
    }

    private func drag(maxOffset: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isLocked, !isBusy else { return }
                offset = min(max(0, value.translation.width), maxOffset)
            }
            .onEnded { _ in
                guard !isLocked, !isBusy else { return }
                if offset >= maxOffset * completionThreshold {
                    withAnimation(.spring) { offset = maxOffset }
                    isBusy = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task {
                        let registered = await onComplete()
                        isBusy = false
                        if !registered {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { offset = 0 }
                        }
                    }
                } else {
                    withAnimation(.spring) { offset = 0 }
                }
            }
    }
}
