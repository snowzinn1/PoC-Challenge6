import SwiftUI
import Combine

/// Semana de registros: cápsulas para sequências de presença/falta,
/// círculo vazio para hoje (sem registro), número para dias futuros.
struct WeeklyAttendanceView: View {
    @ObservedObject var store: AttendanceStore

    // Medidas do design
    private let circleSize: CGFloat = 30
    private let todayCircleSize: CGFloat = 46
    private let rowHeight: CGFloat = 48
    private let capsuleInset: CGFloat = 4

    private static let weekdayNames = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"]

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f
    }()

    private enum StreakType { case present, absent, other }

    private struct StreakGroup: Identifiable {
        let type: StreakType
        let start: Int
        let length: Int
        var id: Int { start }
    }

    var body: some View {
        let days = store.weekDays

        VStack(spacing: 10) {
            header(days)
            circlesRow(days)
            footerRow(days)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Cabeçalho (Seg, Ter...)

    private func header(_ days: [DayCell]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                Text(Self.weekdayNames[index])
                    .font(.system(size: 17))
                    .fontWeight(day.isToday ? .semibold : .regular)
                    .foregroundStyle(labelColor(for: day))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func labelColor(for day: DayCell) -> Color {
        guard day.isToday else { return .primary }
        if case .present = day.state { return .green }   // hoje já registrado
        return .secondary                                 // hoje sem registro
    }

    // MARK: - Linha dos círculos (com as cápsulas atrás)

    private func circlesRow(_ days: [DayCell]) -> some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                dayContent(for: day)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: rowHeight)
        .background { streakBackgrounds(days) }
    }

    private func streakBackgrounds(_ days: [DayCell]) -> some View {
        GeometryReader { geo in
            let itemWidth = geo.size.width / CGFloat(max(days.count, 1))

            ForEach(computeStreaks(days)) { group in
                // só desenha cápsula para sequências de 2 ou mais dias
                if group.type != .other && group.length >= 2 {
                    Capsule()
                        .fill(group.type == .present ? Color.green.opacity(0.2)
                                                      : Color.red.opacity(0.2))
                        .frame(width: itemWidth * CGFloat(group.length) - capsuleInset * 2,
                               height: rowHeight)
                        .offset(x: itemWidth * CGFloat(group.start) + capsuleInset)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func streakType(for day: DayCell) -> StreakType {
        switch day.state {
        case .present: return .present
        case .absent:  return .absent
        case .today, .future: return .other
        }
    }

    private func computeStreaks(_ days: [DayCell]) -> [StreakGroup] {
        guard !days.isEmpty else { return [] }
        var groups: [StreakGroup] = []
        var currentType = streakType(for: days[0])
        var start = 0
        var length = 1

        for i in 1..<days.count {
            let t = streakType(for: days[i])
            if t == currentType {
                length += 1
            } else {
                groups.append(StreakGroup(type: currentType, start: start, length: length))
                currentType = t
                start = i
                length = 1
            }
        }
        groups.append(StreakGroup(type: currentType, start: start, length: length))
        return groups
    }

    // MARK: - Conteúdo de cada dia

    @ViewBuilder
    private func dayContent(for day: DayCell) -> some View {
        switch day.state {
        case .present:
            if day.isToday {
                // Hoje já registrado: anel verde, miolo branco, check verde
                ZStack {
                    Circle().fill(Color.green)
                        .frame(width: todayCircleSize, height: todayCircleSize)
                    Circle().fill(Color.white)
                        .frame(width: circleSize, height: circleSize)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.green)
                }
            } else {
                ZStack {
                    Circle().fill(Color.green)
                        .frame(width: circleSize, height: circleSize)
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(.systemBackground).opacity(0.85))
                }
            }

        case .absent:
            ZStack {
                Circle().fill(Color.red)
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(.systemBackground).opacity(0.85))
            }

        case .today:
            // Hoje sem registro: só o contorno, mesmo tamanho dos outros círculos
            Circle()
                .stroke(Color.secondary.opacity(0.7), lineWidth: 1.5)
                .frame(width: circleSize, height: circleSize)

        case .future:
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 17))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Rodapé (horário exato do registro)

    private func footerRow(_ days: [DayCell]) -> some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                dayFooter(for: day)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 16)
    }

    @ViewBuilder
    private func dayFooter(for day: DayCell) -> some View {
        switch day.state {
        case .present(let date):
            HStack(spacing: 3) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 9))
                Text(Self.timeFormatter.string(from: date))
                    .font(.system(size: 11))
            }
            .foregroundStyle(day.isToday ? Color.primary : Color.secondary)
        case .absent, .today, .future:
            Color.clear
        }
    }
}

#Preview {
    WeeklyAttendanceView(store: AttendanceStore())
        .padding()
}
