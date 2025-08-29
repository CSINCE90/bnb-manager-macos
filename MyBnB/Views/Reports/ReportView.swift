//
//  ReportView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 29/08/25.
//

import SwiftUI

@available(macOS 13.0, *)
struct ReportView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPeriod = "Mese Corrente"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Report Dettagliato")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Chiudi") {
                    dismiss()
                }
            }
            
            // Selezione Periodo
            Picker("Periodo", selection: $selectedPeriod) {
                Text("Settimana").tag("Settimana")
                Text("Mese Corrente").tag("Mese Corrente")
                Text("Anno").tag("Anno")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)
            
            // KPI Cards
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Entrate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", viewModel.entrateTotali))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text("Spese")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", viewModel.speseTotali))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text("Profitto")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", viewModel.profittoNetto))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.profittoNetto > 0 ? .blue : .orange)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Lista Top Prenotazioni
            VStack(alignment: .leading, spacing: 12) {
                Text("Top Prenotazioni")
                    .font(.headline)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.prenotazioni.sorted(by: { $0.prezzoTotale > $1.prezzoTotale }).prefix(5)) { prenotazione in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(prenotazione.nomeOspite)
                                        .fontWeight(.medium)
                                    Text("\(formatDate(prenotazione.dataCheckIn)) - \(formatDate(prenotazione.dataCheckOut))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("€\(String(format: "%.2f", prenotazione.prezzoTotale))")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Bottoni Export
            HStack {
                Button("Esporta PDF") {
                    print("Export PDF")
                }
                
                Button("Esporta Excel") {
                    print("Export Excel")
                }
                
                Button("Esporta CSV") {
                    print("Export CSV")
                }
            }
        }
        .padding(40)
        .frame(width: 800, height: 600)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

