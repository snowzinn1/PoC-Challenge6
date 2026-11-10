//
//  MonthAttendanceCard.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//

import SwiftUI


// MARK: - Cálculo dos dias do mês

enum MonthAttendance {
    static func days(of month: Date, records: [CheckInRecord], weekdaysOnly: Bool,
                     calendar: Calendar = .current, today: Date = Date()) -> [DayStatus] {

        guard let range = calendar.range(of: .day, in: .month, for: month),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        // Indexa os registros por dia (início do dia)
        var presenceDays = Set<Date>()
        var justifiedDays = Set<Date>()
        for r in records {
            let day = calendar.startOfDay(for: r.date)
            switch r.kind {
            case .presence: presenceDays.insert(day)
            case .absence:
                if let j = r.justification, !j.trimmingCharacters(in: .whitespaces).isEmpty {
                    justifiedDays.insert(day)
                }
            }
        }

        let todayStart = calendar.startOfDay(for: today)

        return range.compactMap { offset -> DayStatus? in
            guard let date = calendar.date(byAdding: .day, value: offset - 1, to: start) else { return nil }
            if weekdaysOnly, calendar.isDateInWeekend(date) { return nil }

            if presenceDays.contains(date) { return .present }
            if justifiedDays.contains(date) { return .justifiedAbsence }
            if date > todayStart { return .upcoming }
            if date == todayStart { return .upcoming } // hoje ainda pode registrar
            return .unjustifiedAbsence
        }
    }
}

// MARK: - Bolinha

struct DayDot: View {
    let status: DayStatus
    var size: CGFloat = 10

    var body: some View {
        switch status {
        case .present:
            Circle().fill(Color.primary)
                .frame(width: size, height: size)
        case .justifiedAbsence:
            Circle().fill(Color.primary.opacity(0.28))
                .frame(width: size, height: size)
        case .unjustifiedAbsence:
            Circle().strokeBorder(Color.primary.opacity(0.4), lineWidth: 1)
                .frame(width: size, height: size)
        case .upcoming:
            Circle().fill(Color.primary.opacity(0.10))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Card do mês

struct MonthAttendanceCard: View {
    let month: Date
    let records: [CheckInRecord]
    var weekdaysOnly = true

    private let borderTop: Color = Color.primary.opacity(0.35)
    private let borderBottom: Color = Color.primary.opacity(0.05)

    private var monthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "LLLL"
        return f.string(from: month).capitalized
    }

    private var days: [DayStatus] {
        MonthAttendance.days(of: month, records: records, weekdaysOnly: weekdaysOnly)
    }

    var body: some View {
        GeometryReader { geo in
            content(width: geo.size.width)
        }
        .aspectRatio(1.5, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // Tudo é proporcional à largura do card
    private func content(width w: CGFloat) -> some View {
        let dot: CGFloat = w * 0.045
        let gap: CGFloat = w * 0.03
        let edge: CGFloat = w * 0.085          // margem direita e topo do grid
        let nameInset: CGFloat = w * 0.07    // margem esquerda do nome
        let nameBottom: CGFloat = w * 0.07
        let nameSize: CGFloat = w * 0.11
        let columns: [GridItem] = Array(repeating: GridItem(.fixed(dot), spacing: gap), count: 5)

        return ZStack {
            background

            // Grid de bolinhas: canto superior direito
            LazyVGrid(columns: columns, spacing: gap) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, status in
                    DayDot(status: status, size: dot)
                }
            }
            .padding(.top, edge)
            .padding(.trailing, edge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Nome do mês: canto inferior esquerdo
            Text(monthName)
                .font(.system(size: nameSize, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.leading, nameInset)
                .padding(.bottom, nameBottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let gradient = LinearGradient(colors: [borderTop, borderBottom],
                                      startPoint: .top, endPoint: .bottom)
        return shape
            .fill(Color(.secondarySystemBackground))
            .overlay(shape.strokeBorder(gradient, lineWidth: 1))
    }

    private var accessibilitySummary: String {
        let d = days
        let p = d.filter { $0 == .present }.count
        let j = d.filter { $0 == .justifiedAbsence }.count
        let u = d.filter { $0 == .unjustifiedAbsence }.count
        return "\(monthName): \(p) presenças, \(j) faltas justificadas, \(u) faltas sem justificativa"
    }
}

// MARK: - Tela "Meses de 2026"

struct MonthsOfYearView: View {
    let year: Int
    let repository: CheckInRepository

    @State private var records: [CheckInRecord] = []

    private var months: [Date] {
        (1...12).compactMap {
            Calendar.current.date(from: DateComponents(year: year, month: $0, day: 1))
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(months, id: \.self) { month in
                    MonthAttendanceCard(month: month, records: records)
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Meses de " + String(year))
        .navigationBarTitleDisplayMode(.inline)
        .task { records = await repository.history() }
    }
}

// MARK: - Preview Mock

#Preview {
    NavigationStack {
        MonthsOfYearView(year: 2026, repository: MockCheckInRepository())
    }
    .preferredColorScheme(.dark)
}
