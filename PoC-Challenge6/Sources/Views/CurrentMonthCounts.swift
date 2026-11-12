//
//  CurrentMonthCounts.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 12/11/26.
//

import SwiftUI

// MARK: - Contagem do mês atual

private struct CurrentMonthCounts {
    let presences: Int
    let absences: Int   // justificadas + sem justificativa

    init(records: [CheckInRecord], weekdaysOnly: Bool) {
        let list: [DayStatus] = MonthAttendance.days(of: Date(),
                                                    records: records,
                                                    weekdaysOnly: weekdaysOnly)
        var p = 0
        var a = 0
        for status in list {
            switch status {
            case .present: p += 1
            case .justifiedAbsence: a += 1
            case .unjustifiedAbsence: a += 1
            case .upcoming: break
            }
        }
        presences = p
        absences = a
    }
}

// MARK: - Cores do card (escuro: tons escuros / claro: verde e cinza cheios)

private struct SummaryPalette {
    let scheme: ColorScheme
    private var isDark: Bool { scheme == .dark }

    private let green: Color = Color(red: 0.42, green: 0.78, blue: 0.40)
    private let red: Color = Color(red: 0.90, green: 0.27, blue: 0.24)

    var container: Color { isDark ? Color.clear : Color(.secondarySystemBackground) }
    var containerStroke: Color { isDark ? Color.primary.opacity(0.3) : Color.clear }

    var presenceTile: Color { isDark ? Color(red: 0.07, green: 0.12, blue: 0.09) : green }
    var presenceNumber: Color { isDark ? green : Color.white }

    var absenceTile: Color { isDark ? Color(red: 0.23, green: 0.07, blue: 0.07) : Color(white: 0.45) }
    var absenceNumber: Color { isDark ? red : Color.white }

    var tileTitle: Color { isDark ? Color.primary : Color.white }
}

// MARK: - Quadro com número grande + legenda

private struct StatTile: View {
    let value: Int
    let title: String
    let background: Color
    let numberColor: Color
    let titleColor: Color

    var body: some View {
        GeometryReader { geo in
            tile(width: geo.size.width)
        }
        .aspectRatio(1.55, contentMode: .fit)
    }

    private func tile(width w: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        return ZStack {
            shape.fill(background)

            Text("\(value)")
                .font(.system(size: w * 0.30, weight: .ultraLight))
                .foregroundStyle(numberColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, w * 0.04)
                .padding(.trailing, w * 0.07)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            Text(title)
                .font(.system(size: w * 0.095, weight: .light))
                .foregroundStyle(titleColor)
                .padding(.leading, w * 0.08)
                .padding(.bottom, w * 0.07)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}

// MARK: - Card "Mês Atual"

struct CurrentMonthSummaryCard: View {
    let records: [CheckInRecord]
    var weekdaysOnly: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = SummaryPalette(scheme: colorScheme)
        let counts = CurrentMonthCounts(records: records, weekdaysOnly: weekdaysOnly)
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        return VStack(spacing: 16) {
            Text("Mês Atual")
                .font(.title2)

            HStack(spacing: 16) {
                StatTile(value: counts.presences,
                         title: "Presenças",
                         background: palette.presenceTile,
                         numberColor: palette.presenceNumber,
                         titleColor: palette.tileTitle)

                StatTile(value: counts.absences,
                         title: "Faltas",
                         background: palette.absenceTile,
                         numberColor: palette.absenceNumber,
                         titleColor: palette.tileTitle)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(shape.fill(palette.container))
        .overlay(shape.strokeBorder(palette.containerStroke, lineWidth: 1))
    }
}

// MARK: - Tela completa

struct AttendanceOverviewView: View {
    let year: Int
    let repository: CheckInRepository

    @State private var records: [CheckInRecord] = []

    private var months: [Date] {
        (1...12).compactMap {
            Calendar.current.date(from: DateComponents(year: year, month: $0, day: 1))
        }
    }

    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                YearAttendanceChart(year: year, records: records)

                CurrentMonthSummaryCard(records: records)
                    .padding(.horizontal, 24)

                monthsSection
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .task { records = await repository.history() }
    }

    private var monthsSection: some View {
        VStack(spacing: 20) {
            Text("Meses de " + String(year))
                .font(.headline)

            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(months, id: \.self) { month in
                    MonthAttendanceCard(month: month, records: records)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Escuro") {
    AttendanceOverviewView(year: 2026, repository: MockCheckInRepository())
        .preferredColorScheme(.dark)
}

#Preview("Claro") {
    AttendanceOverviewView(year: 2026, repository: MockCheckInRepository())
        .preferredColorScheme(.light)
}
