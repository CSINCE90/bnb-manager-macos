import SwiftUI

struct CashSnapshotSection: View {
    @ObservedObject var viewModel: GestionaleViewModel

    private var last7: (entrate: Double, uscite: Double) {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let entrate = viewModel.prenotazioni
            .filter { $0.dataCheckIn >= start && $0.dataCheckIn <= Date() && ($0.statoPrenotazione == .confermata || $0.statoPrenotazione == .completata) }
            .reduce(0) { $0 + $1.prezzoTotale }
        let uscite = viewModel.spese
            .filter { $0.data >= start && $0.data <= Date() }
            .reduce(0) { $0 + $1.importo }
        return (entrate, uscite)
    }

    private var next7Expected: Double {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return viewModel.prenotazioni
            .filter { $0.dataCheckIn >= Date() && $0.dataCheckIn <= end && ($0.statoPrenotazione == .confermata || $0.statoPrenotazione == .completata) }
            .reduce(0) { $0 + $1.prezzoTotale }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cash Snapshot").font(.headline)
            HStack(spacing: 16) {
                CashMiniStat(title: "Ultimi 7g Entrate", value: last7.entrate, color: .green)
                CashMiniStat(title: "Ultimi 7g Uscite", value: last7.uscite, color: .red)
                CashMiniStat(title: "Prossimi 7g Previsti", value: next7Expected, color: .blue)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
    }
}

private struct CashMiniStat: View {
    let title: String
    let value: Double
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text("€\(Int(value))").font(.headline).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
