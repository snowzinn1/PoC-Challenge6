//
//  PresenceSlider.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import SwiftUI
import UIKit

/// Slider "deslize para bater o ponto".
/// Estado normal: trilho cinza com botão azul. Estado travado: faixa verde com selo à direita.
struct PresenceSlider: View {
    let isLocked: Bool
    let lockedText: String
    let onComplete: () async -> Bool

    @Environment(\.colorScheme) private var colorScheme

    @State private var offset: CGFloat = 0
    @State private var isBusy = false
    @State private var isDragging = false

    private let trackHeight: CGFloat = 58
    private let knobSize: CGFloat = 46
    private let inset: CGFloat = 6
    private let completionThreshold: CGFloat = 0.85

    private let lockedGreen: Color = Color(red: 0.42, green: 0.78, blue: 0.40)

    var body: some View {
        GeometryReader { geo in
            let maxOffset: CGFloat = max(geo.size.width - knobSize - (inset * 2), 1)

            ZStack {
                if isLocked {
                    lockedTrack
                } else {
                    idleTrack(maxOffset: maxOffset)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isLocked)
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

    // MARK: - Estado travado (ponto batido)

    private var lockedTrack: some View {
        // Escuro: texto e selo pretos. Claro: brancos.
        let contentColor: Color = (colorScheme == .dark) ? Color.black : Color.white

        return ZStack {
            Capsule().fill(lockedGreen)

            HStack {
                Text(lockedText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(contentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(contentColor)
            }
            .padding(.leading, 24)
            .padding(.trailing, 8)
        }
    }

    // MARK: - Estado normal (deslizar)

    private func idleTrack(maxOffset: CGFloat) -> some View {
        let hintOpacity: Double = Double(max(0, 1 - offset / (maxOffset * 0.5)))
        let progressWidth: CGFloat = offset + knobSize + (inset * 2)
        let progressColor: Color = isDragging ? Color.green.opacity(0.35) : Color.blue.opacity(0.25)

        return ZStack(alignment: .leading) {
            Capsule().fill(Color(.secondarySystemBackground))

            Text("Deslize para bater o ponto")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .opacity(hintOpacity)

            // Preenchimento (também forma o "halo" em volta do botão parado)
            Capsule()
                .fill(progressColor)
                .frame(width: progressWidth)
                .animation(.easeInOut(duration: 0.2), value: isDragging)

            knob
                .padding(.leading, inset)
                .offset(x: offset)
                .scaleEffect(isDragging ? 1.03 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                .gesture(drag(maxOffset: maxOffset))
        }
    }

    private var knob: some View {
        let fill: Color = isDragging ? Color.green : Color.blue
        let symbol: String = isDragging ? "hand.draw.fill" : "clock.badge.exclamationmark"

        return ZStack {
            Circle()
                .fill(fill)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

            if isBusy {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: symbol)
                    .font(.headline.bold())
                    .foregroundStyle(Color.white)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3), value: isDragging)
            }
        }
        .frame(width: knobSize, height: knobSize)
    }

    // MARK: - Gesto

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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = maxOffset
                    }
                    isBusy = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    Task {
                        let registered = await onComplete()
                        isBusy = false
                        if !registered {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        }
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
            }
    }
}
