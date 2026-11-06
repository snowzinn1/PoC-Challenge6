//
//  PresenceSlider.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import SwiftUI
import UIKit

/// Slider "deslize para bater o ponto".
struct PresenceSlider: View {
    let isLocked: Bool
    let lockedText: String
    let onComplete: () async -> Bool

    @State private var offset: CGFloat = 0
    @State private var isBusy = false
    @State private var isDragging = false // Estado para detectar o arraste ativo

    private let trackHeight: CGFloat = 64
    private let knobSize: CGFloat = 52
    private let inset: CGFloat = 6
    private let completionThreshold: CGFloat = 0.85
    
    var body: some View {
        GeometryReader { geo in
            let maxOffset = max(geo.size.width - knobSize - (inset * 2), 1)

            ZStack(alignment: .leading) {
                // 1. Barra de Fundo
                Capsule().fill(Color(.secondarySystemBackground))

                if isLocked {
                    // Estado Bloqueado (Ponto batido)
                    Capsule().fill(Color.green.opacity(0.18))
                    Text(lockedText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                } else {
                    // Texto orientativo de fundo (some conforme arrasta)
                    Text("Deslize para bater o ponto")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .opacity(1.0 - (offset / (maxOffset * 0.5))) // Desaparece no começo do arraste

                    // Barra de progresso preenchida dinamicamente
                    Capsule()
                        .fill(isDragging ? Color.green.opacity(0.35) : Color.blue.opacity(0.25))
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                        .frame(width: offset + knobSize + (inset * 2))
                }

                // 2. Botão Arrastável (Thumb)
                ZStack {
                    Circle()
                        .fill(isLocked ? Color.green : isDragging ? Color.green : Color.blue)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

                    if isBusy {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isLocked ? "checkmark" : isDragging ? "hand.draw.fill" : "clock.badge.exclamationmark")
                            .font(.headline.bold())
                            .foregroundStyle(isLocked || isDragging ? Color.white : Color.black.opacity(0.55))
                            .scaleEffect(isDragging ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3), value: isDragging)
                    }
                }
                .frame(width: knobSize, height: knobSize)
                .padding(.leading, inset)
                .offset(x: isLocked ? maxOffset : offset)
                .scaleEffect(isDragging ? 1.03 : 1.0) // Leve efeito de expansão ao segurar
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .gesture(drag(maxOffset: maxOffset))
            }
        }
        .frame(height: trackHeight)
        .onChange(of: isLocked) { _, locked in
            if !locked {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = 0
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isLocked ? lockedText : "Deslize para bater o ponto")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard !isLocked, !isBusy else { return }
            Task {
                isBusy = true
                let registered = await onComplete()
                isBusy = false
                if !registered {
                    withAnimation(.spring) { offset = 0 }
                }
            }
        }
    }

    private func drag(maxOffset: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isLocked, !isBusy else { return }
                isDragging = true
                offset = min(max(0, value.translation.width), maxOffset)
            }
            .onEnded { _ in
                guard !isLocked, !isBusy else { return }
                isDragging = false
                
                if offset >= maxOffset * completionThreshold {
                    // Completa o deslize
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = maxOffset
                    }
                    isBusy = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    
                    Task {
                        let registered = await onComplete()
                        isBusy = false
                        if !registered {
                            // Se falhar (ex: Face ID negado), retorna ao início suavemente
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        }
                    }
                } else {
                    // Soltou antes do limite, cancela e volta
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
            }
    }
}
