//
//  DashboardView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Header con statistiche principali
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        // Cards delle statistiche
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Entrate Totali",
                                value: String(format: "€%.0f", viewModel.entrateTotali),
                                systemImage: "eurosign.circle.fill",
                                backgroundColor: .green
                            )
                            
                            StatCard(
                                title: "Spese Totali",
                                value: String(format: "€%.0f", viewModel.speseTotali),
                                systemImage: "creditcard.fill",
                                backgroundColor: .red
                            )
                            
                            StatCard(
                                title: "Profitto Netto",
                                value: String(format: "€%.0f", viewModel.profittoNetto),
                                systemImage: "chart.line.uptrend.xyaxis",
                                backgroundColor: .blue
                            )
                            
                            StatCard(
                                title: "Prenotazioni Attive",
                                value: "\(viewModel.prenotazioniAttive.count)",
                                systemImage: "calendar.badge.clock",
                                backgroundColor: .purple
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Prossime prenotazioni
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Prossime Prenotazioni")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            
                            NavigationLink("Vedi Tutte") {
                                PrenotazioniView(viewModel: viewModel)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.prenotazioniAttive.isEmpty {
                            Text("Nessuna prenotazione attiva")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(Array(viewModel.prenotazioniAttive.prefix(3))) { prenotazione in
                                PrenotazioneRowView(prenotazione: prenotazione)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
        }
    }


// View per le righe delle prenotazioni nella dashboard
struct PrenotazioneRowView: View {
    let prenotazione: Prenotazione
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prenotazione.nomeOspite)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("\(dateFormatter.string(from: prenotazione.dataCheckIn)) - \(dateFormatter.string(from: prenotazione.dataCheckOut))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "€%.0f", prenotazione.prezzoTotale))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(prenotazione.statoPrenotazione.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(prenotazione.statoPrenotazione.colore.opacity(0.2))
                    .foregroundColor(prenotazione.statoPrenotazione.colore)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    DashboardView(viewModel: GestionaleViewModel())
}
