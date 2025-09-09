import SwiftUI

struct AlertsSection: View {
    @ObservedObject var viewModel: GestionaleViewModel

    private var alerts: [String] {
        var items: [String] = []
        let calendar = Calendar.current
        let today = Date()

        // 1) Prenotazioni passate non marcate completate
        let pastNotCompleted = viewModel.prenotazioni.filter {
            $0.dataCheckOut < today && $0.statoPrenotazione != .completata && $0.statoPrenotazione != .cancellata
        }
        if !pastNotCompleted.isEmpty {
            items.append("\(pastNotCompleted.count) prenotazioni passate da chiudere")
        }

        // 2) Gap di calendario > 3 giorni nei prossimi 30 giorni
        let upcoming = viewModel.prenotazioni
            .filter { $0.dataCheckIn >= today }
            .sorted { $0.dataCheckIn < $1.dataCheckIn }
        if upcoming.count >= 2 {
            for i in 0..<(upcoming.count - 1) {
                let a = upcoming[i]
                let b = upcoming[i+1]
                let gap = calendar.dateComponents([.day], from: a.dataCheckOut, to: b.dataCheckIn).day ?? 0
                if gap >= 3 {
                    items.append("Finestra libera di \(gap) giorni tra \(formatDate(a.dataCheckOut)) e \(formatDate(b.dataCheckIn))")
                    break
                }
            }
        }

        // 3) Check-in entro 7 giorni senza note/telefono (promemoria contatto)
        let soon = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let missingContact = viewModel.prenotazioni.filter {
            $0.dataCheckIn >= today && $0.dataCheckIn <= soon && ($0.telefono.isEmpty)
        }
        if !missingContact.isEmpty {
            items.append("\(missingContact.count) ospiti in arrivo senza telefono")
        }

        return items
    }

    var body: some View {
        if alerts.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Avvisi", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.headline)
                    Spacer()
                }
                ForEach(Array(alerts.enumerated()), id: \.offset) { _, text in
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "dot.circle.fill").foregroundColor(.orange)
                        Text(text).font(.caption)
                        Spacer()
                    }
                }
                HStack {
                    Button("Marca prenotazioni passate completate") {
                        markPastAsCompleted()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }

    private func markPastAsCompleted() {
        let today = Date()
        let targets = viewModel.prenotazioni.filter { $0.dataCheckOut < today && $0.statoPrenotazione != .completata && $0.statoPrenotazione != .cancellata }
        for var p in targets {
            p.statoPrenotazione = .completata
            viewModel.modificaPrenotazione(p)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return f.string(from: date)
    }
}
