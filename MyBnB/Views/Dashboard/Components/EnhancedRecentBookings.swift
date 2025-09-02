//
//  EnhancedRecentBookings.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE 8: Dashboard/Components/EnhancedRecentBookings.swift =====

import SwiftUI

struct EnhancedRecentBookings: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var selectedBooking: Prenotazione?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Prenotazioni Recenti")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.prenotazioniAttive.isEmpty {
                    Text("\(viewModel.prenotazioniAttive.count) attive")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.prenotazioniAttive.isEmpty {
                EmptyStateCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.prenotazioniAttive.prefix(5)) { prenotazione in
                            BookingCard(
                                prenotazione: prenotazione,
                                isSelected: selectedBooking?.id == prenotazione.id
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedBooking = prenotazione
                                }
                            }
                        }
                    }
                }
            }
            
            if let booking = selectedBooking {
                BookingDetailCard(booking: booking)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
}

struct BookingCard: View {
    let prenotazione: Prenotazione
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(prenotazione.statoPrenotazione.colore)
                    .frame(width: 10, height: 10)
                
                Text(prenotazione.nomeOspite)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Label(formatDate(prenotazione.dataCheckIn), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(prenotazione.numeroOspiti)")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("€\(Int(prenotazione.prezzoTotale))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : .black.opacity(0.05),
                       radius: isSelected ? 8 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

struct BookingDetailCard: View {
    let booking: Prenotazione
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dettagli Prenotazione")
                .font(.callout)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Ospite", systemImage: "person")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text(booking.nomeOspite)
                        .fontWeight(.medium)
                        .font(.caption)
                }
                
                HStack {
                    Label("Email", systemImage: "envelope")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text(booking.email)
                        .font(.caption)
                }
                
                HStack {
                    Label("Periodo", systemImage: "calendar")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text("\(formatDate(booking.dataCheckIn)) - \(formatDate(booking.dataCheckOut))")
                        .font(.caption)
                }
                
                HStack {
                    Label("Totale", systemImage: "eurosign")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text("€\(String(format: "%.2f", booking.prezzoTotale))")
                        .fontWeight(.semibold)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Nessuna prenotazione attiva")
                .font(.headline)
            
            Text("Le nuove prenotazioni appariranno qui")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.secondary.opacity(0.3))
                )
        )
    }
}
