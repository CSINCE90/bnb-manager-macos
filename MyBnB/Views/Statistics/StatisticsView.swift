//
//  StatisticsView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 29/08/25.
//

//
//  StatisticsView.swift - VERSIONE SEMPLIFICATA
//  MyBnB
//
//  📍 PERCORSO: MyBnB/Views/Statistics/StatisticsView.swift
//

import SwiftUI

@available(macOS 13.0, *)
struct StatisticsView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    var mediaGiorniSoggiorno: Double {
        guard !viewModel.prenotazioni.isEmpty else { return 0 }
        let totaleGiorni = viewModel.prenotazioni.reduce(0) { $0 + $1.numeroNotti }
        return Double(totaleGiorni) / Double(viewModel.prenotazioni.count)
    }
    
    var mediaOspitiPerPrenotazione: Double {
        guard !viewModel.prenotazioni.isEmpty else { return 0 }
        let totaleOspiti = viewModel.prenotazioni.reduce(0) { $0 + $1.numeroOspiti }
        return Double(totaleOspiti) / Double(viewModel.prenotazioni.count)
    }
    
    var ricavoMedioPerPrenotazione: Double {
        guard !viewModel.prenotazioni.isEmpty else { return 0 }
        return viewModel.entrateTotali / Double(viewModel.prenotazioni.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Statistiche Avanzate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Chiudi") {
                    dismiss()
                }
            }
            
            // Grid Statistiche
            HStack(spacing: 16) {
                StatCardSimple(
                    title: "Media Giorni",
                    value: String(format: "%.1f", mediaGiorniSoggiorno),
                    subtitle: "per soggiorno",
                    color: .blue
                )
                
                StatCardSimple(
                    title: "Media Ospiti",
                    value: String(format: "%.1f", mediaOspitiPerPrenotazione),
                    subtitle: "per prenotazione",
                    color: .green
                )
                
                StatCardSimple(
                    title: "Ricavo Medio",
                    value: String(format: "€%.0f", ricavoMedioPerPrenotazione),
                    subtitle: "per prenotazione",
                    color: .orange
                )
            }
            
            // Tabella Riepilogo
            VStack(alignment: .leading, spacing: 12) {
                Text("Riepilogo Generale")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Totale Prenotazioni:")
                        Spacer()
                        Text("\(viewModel.prenotazioni.count)")
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Prenotazioni Confermate:")
                        Spacer()
                        Text("\(viewModel.prenotazioni.filter { $0.statoPrenotazione == .confermata }.count)")
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Prenotazioni in Attesa:")
                        Spacer()
                        Text("\(viewModel.prenotazioni.filter { $0.statoPrenotazione == .inAttesa }.count)")
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Totale Categorie Spese:")
                        Spacer()
                        Text("\(Set(viewModel.spese.map { $0.categoria }).count)")
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(40)
        .frame(width: 700, height: 500)
    }
}

// MARK: - Stat Card Simple
struct StatCardSimple: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// Versione per macOS < 13 già inclusa in EnhancedDashboardView.swift come SimpleStatisticsView
