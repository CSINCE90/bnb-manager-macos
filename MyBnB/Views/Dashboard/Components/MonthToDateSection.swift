import SwiftUI

struct MonthToDateSection: View {
    @ObservedObject var viewModel: GestionaleViewModel

    private var mtd: (entrate: Double, spese: Double, saldo: Double, prev: Double) {
        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let prevMonthEnd = cal.date(byAdding: DateComponents(day: -1), to: startOfMonth) ?? now
        let startOfPrev = cal.date(from: cal.dateComponents([.year, .month], from: prevMonthEnd)) ?? prevMonthEnd

        // Entrate/spese MTD
        let entrate = viewModel.prenotazioni
            .filter { $0.dataCheckIn >= startOfMonth && $0.dataCheckIn <= now && ($0.statoPrenotazione == .confermata || $0.statoPrenotazione == .completata) }
            .reduce(0) { $0 + $1.prezzoTotale }

        let spese = viewModel.spese
            .filter { $0.data >= startOfMonth && $0.data <= now }
            .reduce(0) { $0 + $1.importo }

        let saldo = entrate - spese

        // Mese precedente (stesso range di giorni)
        let dayCount = cal.dateComponents([.day], from: startOfMonth, to: now).day ?? 0
        let prevRangeEnd = cal.date(byAdding: .day, value: dayCount, to: startOfPrev) ?? prevMonthEnd
        let prevEntrate = viewModel.prenotazioni
            .filter { $0.dataCheckIn >= startOfPrev && $0.dataCheckIn <= prevRangeEnd && ($0.statoPrenotazione == .confermata || $0.statoPrenotazione == .completata) }
            .reduce(0) { $0 + $1.prezzoTotale }
        let prevSpese = viewModel.spese
            .filter { $0.data >= startOfPrev && $0.data <= prevRangeEnd }
            .reduce(0) { $0 + $1.importo }
        let prevSaldo = prevEntrate - prevSpese

        return (entrate, spese, saldo, prevSaldo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Andamento Mese (MTD)").font(.headline)
                Spacer()
                DiffTag(value: mtd.saldo - mtd.prev)
            }
            HStack(spacing: 16) {
                MiniStat(title: "Entrate", value: mtd.entrate, color: .green)
                MiniStat(title: "Spese", value: mtd.spese, color: .red)
                MiniStat(title: "Saldo", value: mtd.saldo, color: mtd.saldo >= 0 ? .blue : .orange)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
    }
}

private struct MiniStat: View {
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

private struct DiffTag: View {
    let value: Double
    var body: some View {
        let positive = value >= 0
        return Text("\(positive ? "+" : "-")€\(Int(abs(value)))")
            .font(.caption)
            .foregroundColor(positive ? .green : .red)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background((positive ? Color.green : Color.red).opacity(0.1))
            .cornerRadius(12)
    }
}

