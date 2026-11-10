//
//  MonthProportion.swift
//  PoC-Challenge6
//
//  Created by Tais Akemi Kawaguti on 10/11/26.
//

import SwiftUI

// MARK: - Cores (nomeadas para o compilador não precisar inferir)

enum AttendanceColors {
    static let present: Color = Color.primary
    static let justified: Color = Color.primary.opacity(0.28)
    static let unjustifiedStroke: Color = Color.primary.opacity(0.35)
    static let emptyStroke: Color = Color.primary.opacity(0.12)
}

// MARK: - Modelo

struct MonthProportion: Identifiable {
    let id: Int
    let label: String
    let present: Int
    let justified: Int
    let unjustified: Int

    var total: Int { present + justified + unjustified }
}

extension MonthAttendance {
    static func proportions(year: Int, records: [CheckInRecord], weekdaysOnly: Bool = true) -> [MonthProportion] {
        let calendar: Calendar = Calendar.current
        let labels: [String] = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
        var result: [MonthProportion] = []

        for m in 1...12 {
            var comps = DateComponents()
            comps.year = year
            comps.month = m
            comps.day = 1
            let month: Date = calendar.date(from: comps) ?? Date()

            let list: [DayStatus] = MonthAttendance.days(of: month,
                                                        records: records,
                                                        weekdaysOnly: weekdaysOnly)
            var p = 0
            var j = 0
            var u = 0
            for status in list {
                switch status {
                case .present: p += 1
                case .justifiedAbsence: j += 1
                case .unjustifiedAbsence: u += 1
                case .upcoming: break
                }
            }

            let item = MonthProportion(id: m, label: labels[m - 1],
                                       present: p, justified: j, unjustified: u)
            result.append(item)
        }
        return result
    }
}

// MARK: - Segmentos da barra

private struct PresenceSegment: View {
    let height: CGFloat
    let width: CGFloat
    var body: some View {
        Capsule()
            .fill(AttendanceColors.present)
            .frame(width: width, height: height)
    }
}

private struct JustifiedSegment: View {
    let height: CGFloat
    let width: CGFloat
    var body: some View {
        Capsule()
            .fill(AttendanceColors.justified)
            .frame(width: width, height: height)
    }
}

private struct UnjustifiedSegment: View {
    let height: CGFloat
    let width: CGFloat
    var body: some View {
        Capsule()
            .stroke(AttendanceColors.unjustifiedStroke, lineWidth: 1.5)
            .frame(width: width, height: height)
    }
}

private struct EmptySegment: View {
    let height: CGFloat
    let width: CGFloat
    var body: some View {
        Capsule()
            .stroke(AttendanceColors.emptyStroke, lineWidth: 1.5)
            .frame(width: width, height: height)
    }
}

// MARK: - Barra proporcional

struct ProportionBar: View {
    let data: MonthProportion
    let height: CGFloat
    var width: CGFloat = 15
    var spacing: CGFloat = 4

    private struct Heights {
        var unjustified: CGFloat = 0
        var justified: CGFloat = 0
        var present: CGFloat = 0
    }

    private func segmentHeight(count: Int, total: CGFloat, available: CGFloat) -> CGFloat {
        if count == 0 { return 0 }
        let proportional: CGFloat = CGFloat(count) / total * available
        return Swift.max(proportional, width)
    }

    private func computeHeights() -> Heights {
        var result = Heights()
        if data.total == 0 { return result }

        var visible: Int = 0
        if data.unjustified > 0 { visible += 1 }
        if data.justified > 0 { visible += 1 }
        if data.present > 0 { visible += 1 }

        let gaps: CGFloat = spacing * CGFloat(Swift.max(visible - 1, 0))
        let available: CGFloat = height - gaps
        let total: CGFloat = CGFloat(data.total)

        var u: CGFloat = segmentHeight(count: data.unjustified, total: total, available: available)
        var j: CGFloat = segmentHeight(count: data.justified, total: total, available: available)
        var p: CGFloat = segmentHeight(count: data.present, total: total, available: available)

        let sum: CGFloat = u + j + p
        if sum > available {
            let scale: CGFloat = available / sum
            u *= scale
            j *= scale
            p *= scale
        }

        result.unjustified = u
        result.justified = j
        result.present = p
        return result
    }

    var body: some View {
        let h: Heights = computeHeights()

        return VStack(spacing: spacing) {
            if data.total == 0 {
                EmptySegment(height: height, width: width)
            }
            if data.unjustified > 0 {
                UnjustifiedSegment(height: h.unjustified, width: width)
            }
            if data.justified > 0 {
                JustifiedSegment(height: h.justified, width: width)
            }
            if data.present > 0 {
                PresenceSegment(height: h.present, width: width)
            }
        }
        .frame(height: height, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let a = "\(data.label): \(data.present) presenças"
        let b = "\(data.justified) faltas justificadas"
        let c = "\(data.unjustified) faltas"
        return a + ", " + b + ", " + c
    }
}

// MARK: - Legenda

private struct LegendDot: View {
    enum Style { case present, justified, unjustified }
    let style: Style

    var body: some View {
        ZStack {
            switch style {
            case .present:
                Circle().fill(AttendanceColors.present)
            case .justified:
                Circle().fill(AttendanceColors.justified)
            case .unjustified:
                Circle().stroke(AttendanceColors.unjustifiedStroke, lineWidth: 1.5)
            }
        }
        .frame(width: 15, height: 15)
    }
}

private struct LegendItem: View {
    let style: LegendDot.Style
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            LegendDot(style: style)
            Text(title)
                .font(.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct ChartLegend: View {
    var body: some View {
        HStack {
            LegendItem(style: .present, title: "Presença")
            Spacer(minLength: 5)
            LegendItem(style: .justified, title: "Faltas Justificada")
            Spacer(minLength: 5)
            LegendItem(style: .unjustified, title: "Faltas")
        }
    }
}

// MARK: - Coluna de um mês

private struct MonthColumn: View {
    let month: MonthProportion
    let appeared: Bool

    var body: some View {
        let delay: Double = Double(month.id) * 0.03
        let animation: Animation = Animation
            .spring(response: 0.6, dampingFraction: 0.85)
            .delay(delay)
        let scaleY: CGFloat = appeared ? 1.0 : 0.01

        return VStack(spacing: 14) {
            ProportionBar(data: month, height: 150)
                .scaleEffect(x: 1.0, y: scaleY, anchor: .bottom)
                .animation(animation, value: appeared)

            Text(month.label)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Gráfico anual

struct YearAttendanceChart: View {
    let year: Int
    let records: [CheckInRecord]
    var weekdaysOnly: Bool = true

    @State private var appeared: Bool = false

    var body: some View {
        let months: [MonthProportion] = MonthAttendance.proportions(year: year,
                                                                    records: records,
                                                                    weekdaysOnly: weekdaysOnly)
        return VStack(alignment: .leading, spacing: 32) {
            Text(String(year))
                .font(.system(size: 56, weight: .bold))

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(months) { month in
                    MonthColumn(month: month, appeared: appeared)
                }
            }

            ChartLegend()
        }
        .padding(24)
        .onAppear { appeared = true }
    }
}

// MARK: - Tela

struct AttendanceYearScreen: View {
    let year: Int
    let repository: CheckInRepository

    @State private var records: [CheckInRecord] = []

    var body: some View {
        ScrollView {
            YearAttendanceChart(year: year, records: records)
        }
        .task {
            records = await repository.history()
        }
    }
}

#Preview {
    AttendanceYearScreen(year: 2026, repository: MockCheckInRepository())
        .preferredColorScheme(.dark)
}
