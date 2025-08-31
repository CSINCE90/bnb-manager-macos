//
//  PrenotazioniView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//
import SwiftUI

struct PrenotazioniView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var mostraAggiungiPrenotazione = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.prenotazioni) { prenotazione in
                        PrenotazioneCardView(prenotazione: prenotazione)
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let index = viewModel.prenotazioni.firstIndex(where: { $0.id == prenotazione.id }) {
                                        viewModel.eliminaPrenotazione(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
            .navigationTitle("Prenotazioni")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        mostraAggiungiPrenotazione = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostraAggiungiPrenotazione) {
                AggiungiPrenotazioneView(viewModel: viewModel)
                    .frame(minWidth: 600, minHeight: 500)
            }
        }
    }
}

struct PrenotazioneCardView: View {
    let prenotazione: Prenotazione
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prenotazione.nomeOspite)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(prenotazione.statoPrenotazione.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(prenotazione.statoPrenotazione.colore.opacity(0.2))
                    .foregroundColor(prenotazione.statoPrenotazione.colore)
                    .cornerRadius(6)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Check-in: \(dateFormatter.string(from: prenotazione.dataCheckIn))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Check-out: \(dateFormatter.string(from: prenotazione.dataCheckOut))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "€%.0f", prenotazione.prezzoTotale))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(prenotazione.numeroOspiti) ospiti • \(prenotazione.numeroNotti) notti")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !prenotazione.note.isEmpty {
                Text(prenotazione.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    PrenotazioniView(viewModel: GestionaleViewModel())
}
