import SwiftUI

struct WeeklyTimelineSection: View {
    @ObservedObject var viewModel: GestionaleViewModel

    private var days: [Date] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prossimi 7 giorni").font(.headline)
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    WeeklyDayCell(date: day, events: events(on: day))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
    }

    struct DayEvent: Identifiable {
        enum Kind { case checkin, checkout }
        let id = UUID()
        let kind: Kind
        let prenotazione: Prenotazione
    }

    private func events(on day: Date) -> [DayEvent] {
        let cal = Calendar.current
        var items: [DayEvent] = []
        for p in viewModel.prenotazioni {
            if cal.isDate(p.dataCheckIn, inSameDayAs: day) {
                items.append(DayEvent(kind: .checkin, prenotazione: p))
            }
            if cal.isDate(p.dataCheckOut, inSameDayAs: day) {
                items.append(DayEvent(kind: .checkout, prenotazione: p))
            }
        }
        return items
    }
}

private struct WeeklyDayCell: View {
    let date: Date
    let events: [WeeklyTimelineSection.DayEvent]
    var body: some View {
        let cal = Calendar.current
        let df = DateFormatter(); df.dateFormat = "E"; df.locale = Locale(identifier: "it_IT")
        let dLabel = df.string(from: date).capitalized
        let dayNum = cal.component(.day, from: date)
        return VStack(spacing: 6) {
            Text("\(dLabel) \(dayNum)").font(.caption).foregroundColor(.secondary)
            if events.isEmpty {
                Text("—").font(.caption2).foregroundColor(.secondary)
            } else {
                ForEach(events.prefix(2)) { e in
                    Text((e.kind == .checkin ? "Check‑in: " : "Check‑out: ") + e.prenotazione.nomeOspite)
                        .font(.caption2)
                        .lineLimit(1)
                }
                if events.count > 2 { Text("+\(events.count - 2)").font(.caption2) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.08)))
    }
}
