//
//  CheckInday.swift
//  PoC-Challenge6
//
//  Created by Guilherme Alves de Souza on 03/11/26.
//

import SwiftUI

/// Card de um dia na faixa "Registros".
struct DayCard: View {
    let day: DayCell

    private static let weekdayNames = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    private var weekdayName: String {
        let index = Calendar.current.component(.weekday, from: day.date) - 1
        return Self.weekdayNames[index]
    }

    private var dateText: String {
        let parts = Calendar.current.dateComponents([.day, .month], from: day.date)
        return String(format: "%02d/%02d", parts.day ?? 0, parts.month ?? 0)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(weekdayName).font(.headline)
            Text(dateText).font(.caption)

            Spacer(minLength: 0)
            icon
            Spacer(minLength: 0)

            footer.frame(height: 16)
        }
        .padding(.vertical, 12)
        .frame(width: 88, height: 148)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            if day.isToday {
                RoundedRectangle(cornerRadius: 16).stroke(Color.orange, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch day.state {
        case .present:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32)).foregroundStyle(.green)
        case .absent:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32)).foregroundStyle(.red)
        case .today:
            Color.clear.frame(width: 32, height: 32)
        case .future:
            Text("-").font(.title3.weight(.semibold))
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch day.state {
        case .present(let date):
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                Text(date.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption2).foregroundStyle(.secondary)
        case .absent(let justified):
            Text(justified ? "Justificada" : "-")
                .font(.caption2)
                .foregroundStyle(justified ? Color.orange : Color.secondary)
        case .today:
            Text("Hoje").font(.caption2).foregroundStyle(.secondary)
        case .future:
            EmptyView()
        }
    }
}
