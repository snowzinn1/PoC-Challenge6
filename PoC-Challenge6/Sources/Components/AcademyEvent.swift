//
//  AcademyEvent.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 11/11/26.
//

import SwiftUI

// MARK: - Modelo

struct AcademyEvent: Identifiable, Equatable {
    let id: UUID
    let title: String
    let start: Date

    init(id: UUID = UUID(), title: String, start: Date) {
        self.id = id
        self.title = title
        self.start = start
    }
}

// MARK: - Fronteira com o "servidor"

protocol EventRepository {
    func events(on day: Date) async -> [AcademyEvent]
}

/// Dados locais para a PoC. No app real, basta outra implementação que chame o WebService.
struct MockEventRepository: EventRepository {
    func events(on day: Date) async -> [AcademyEvent] {
        let calendar: Calendar = Calendar.current
        guard calendar.isDateInToday(day) else { return [] }

        let keynote: Date = calendar.date(bySettingHour: 13, minute: 2, second: 0, of: day) ?? day
        let engage: Date = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: day) ?? day
        return [
            AcademyEvent(title: "Keynote", start: keynote),
            AcademyEvent(title: "Engage", start: engage)
        ]
    }
}

// MARK: - Paleta (escuro: cinzas / claro: card de hoje azul)

private struct EventPalette {
    let scheme: ColorScheme

    private var isDark: Bool { scheme == .dark }

    private let lightBlue: Color = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let lightNextCard: Color = Color(red: 0.77, green: 0.81, blue: 0.89)
    private let lightNextText: Color = Color(red: 0.24, green: 0.43, blue: 0.80)

    // Card de hoje
    var todayCard: Color { isDark ? Color.primary.opacity(0.08) : lightBlue }
    var todayText: Color { isDark ? Color.primary : Color.white }
    var todayTextDimmed: Color { isDark ? Color.primary.opacity(0.4) : Color.white }
    var todayHighlight: Color { isDark ? Color.primary.opacity(0.18) : Color.black.opacity(0.22) }

    // Card do dia seguinte
    var nextCard: Color { isDark ? Color.primary.opacity(0.05) : lightNextCard }
    var nextText: Color { isDark ? Color.primary.opacity(0.55) : lightNextText }
    var nextNumber: Color { isDark ? Color.primary : lightNextText }
    var nextHighlight: Color { isDark ? Color.primary.opacity(0.18) : Color.white.opacity(0.5) }

    // Cabeçalho da seção
    var secondary: Color { Color.primary.opacity(0.55) }
}

// MARK: - Formatação

private enum EventFormat {
    static func dayNumber(_ date: Date) -> String {
        let day: Int = Calendar.current.component(.day, from: date)
        return String(format: "%02d", day)
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Linha de um evento

private struct EventRow: View {
    let event: AcademyEvent
    let isHighlighted: Bool
    let isPrimary: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var palette: EventPalette { EventPalette(scheme: colorScheme) }

    private var textColor: Color {
        if isPrimary {
            return isHighlighted ? palette.todayText : palette.todayTextDimmed
        }
        return palette.nextText
    }

    private var highlightFill: Color {
        isPrimary ? palette.todayHighlight : palette.nextHighlight
    }

    var body: some View {
        let weight: Font.Weight = isHighlighted ? .semibold : .regular

        return HStack(spacing: 8) {
            Text(event.title)
                .font(.body)
                .lineLimit(1)

            Spacer(minLength: 8)

            Image(systemName: "clock.fill")
                .font(.subheadline)

            Text(EventFormat.time(event.start))
                .font(.body.weight(weight))
                .monospacedDigit()
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(rowBackground)
    }

    private var rowBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let fill: Color = isHighlighted ? highlightFill : Color.clear
        return shape.fill(fill)
    }
}

// MARK: - Card de um dia

private struct DayEventsCard: View {
    let day: Date
    let events: [AcademyEvent]
    let isPrimary: Bool
    let now: Date

    @Environment(\.colorScheme) private var colorScheme

    private var palette: EventPalette { EventPalette(scheme: colorScheme) }

    private var visibleEvents: [AcademyEvent] {
        let limit: Int = isPrimary ? 2 : 1
        return Array(events.prefix(limit))
    }

    /// O destaque vai para o próximo evento que ainda não começou (ou o primeiro, se todos já passaram).
    private var highlightedID: UUID? {
        let upcoming: AcademyEvent? = events.first(where: { $0.start >= now })
        return (upcoming ?? events.first)?.id
    }

    private var numberColor: Color {
        isPrimary ? palette.todayText : palette.nextNumber
    }

    var body: some View {
        let numberSize: CGFloat = isPrimary ? 64 : 32
        let numberWeight: Font.Weight = isPrimary ? .ultraLight : .thin
        let fillColor: Color = isPrimary ? palette.todayCard : palette.nextCard
        let numberWidth: CGFloat = isPrimary ? 90 : 70
        let hPadding: CGFloat = isPrimary ? 16 : 12
        let vPadding: CGFloat = isPrimary ? 22 : 12

        return HStack(alignment: .center, spacing: 12) {
            Text(EventFormat.dayNumber(day))
                .font(.system(size: numberSize, weight: numberWeight))
                .foregroundStyle(numberColor)
                .frame(width: numberWidth, alignment: .center)

            eventsContent
        }
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(fillColor)
        )
    }

    @ViewBuilder
    private var eventsContent: some View {
        if events.isEmpty {
            Text("Sem eventos")
                .font(.body)
                .foregroundStyle(isPrimary ? palette.todayText : palette.nextText)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 14)
        } else {
            VStack(spacing: 6) {
                ForEach(visibleEvents) { event in
                    EventRow(event: event,
                             isHighlighted: event.id == highlightedID,
                             isPrimary: isPrimary)
                }
            }
        }
    }
}

// MARK: - Seção completa: "Eventos de hoje"

/// O espaçamento horizontal da tela fica por conta de quem usa (ex.: HomeView).
struct TodayEventsSection: View {
    let repository: EventRepository
    var onSeeMore: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme

    @State private var today: [AcademyEvent] = []
    @State private var tomorrow: [AcademyEvent] = []

    private var todayDate: Date { Date() }

    private var tomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 10) {
                DayEventsCard(day: todayDate, events: today, isPrimary: true, now: Date())

                DayEventsCard(day: tomorrowDate, events: tomorrow, isPrimary: false, now: Date())
                    .padding(.horizontal, 10)
            }
        }
        .task { await load() }
    }

    private var header: some View {
        let secondary: Color = EventPalette(scheme: colorScheme).secondary

        return HStack {
            Text("Eventos de hoje")
                .font(.title3)
            Spacer()
            Button(action: onSeeMore) {
                Text("ver mais")
                    .font(.title3)
                    .foregroundStyle(secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func load() async {
        let todayEvents: [AcademyEvent] = await repository.events(on: todayDate)
        let tomorrowEvents: [AcademyEvent] = await repository.events(on: tomorrowDate)
        today = todayEvents.sorted { $0.start < $1.start }
        tomorrow = tomorrowEvents.sorted { $0.start < $1.start }

        // Agenda os lembretes de "faltam 20 minutos" para o que ainda não começou
        await EventNotificationManager.shared.scheduleReminders(for: today + tomorrow)
    }
}

#Preview("Escuro") {
    TodayEventsSection(repository: MockEventRepository())
        .padding(20)
        .preferredColorScheme(.dark)
}

#Preview("Claro") {
    TodayEventsSection(repository: MockEventRepository())
        .padding(20)
        .preferredColorScheme(.light)
}
