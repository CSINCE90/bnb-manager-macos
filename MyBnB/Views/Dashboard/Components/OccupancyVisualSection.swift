import SwiftUI

struct OccupancyVisualSection: View {
    @ObservedObject var viewModel: GestionaleViewModel
    
    var currentReservation: Prenotazione? {
        let today = Date()
        return viewModel.prenotazioniAttive.first { prenotazione in
            prenotazione.dataCheckIn <= today && prenotazione.dataCheckOut >= today
        }
    }
    
    var nextReservation: Prenotazione? {
        let today = Date()
        return viewModel.prenotazioni
            .filter { $0.dataCheckIn > today }
            .sorted { $0.dataCheckIn < $1.dataCheckIn }
            .first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Stato Casa Vacanze")
                    .font(.headline)
                
                Spacer()
                
                Text("Max 4 ospiti")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Status principale della casa
            if let current = currentReservation {
                CurrentGuestCard(prenotazione: current)
            } else {
                EmptyHouseCard(nextReservation: nextReservation)
            }
            
            // Operazioni giornaliere
            HStack(spacing: 16) {
                // Check-in oggi
                DailyOperationCard(
                    title: "Check-in Oggi",
                    guests: todayCheckInGuests(),
                    icon: "key.fill",
                    color: .green
                )
                
                // Check-out oggi
                DailyOperationCard(
                    title: "Check-out Oggi",
                    guests: todayCheckOutGuests(),
                    icon: "door.left.hand.open",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    // Lista ospiti in check-in oggi
    private func todayCheckInGuests() -> [Prenotazione] {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni
            .filter { calendar.isDate($0.dataCheckIn, inSameDayAs: today) }
    }
    
    // Lista ospiti in check-out oggi
    private func todayCheckOutGuests() -> [Prenotazione] {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni
            .filter { calendar.isDate($0.dataCheckOut, inSameDayAs: today) }
    }
}

// MARK: - Current Guest Card
struct CurrentGuestCard: View {
    let prenotazione: Prenotazione
    
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: prenotazione.dataCheckOut).day ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            VStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("OCCUPATA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // Guest info
            VStack(alignment: .leading, spacing: 6) {
                Text(prenotazione.nomeOspite)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(prenotazione.numeroOspiti) ospiti")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Check-out:")
                        .foregroundColor(.secondary)
                    Text(formatDate(prenotazione.dataCheckOut))
                        .fontWeight(.medium)
                }
                .font(.callout)
                
                if daysRemaining > 0 {
                    Text("\(daysRemaining) giorni rimanenti")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Revenue info
            VStack(alignment: .trailing, spacing: 4) {
                Text("€\(String(format: "%.0f", prenotazione.prezzoTotale))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Ricavo totale")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// MARK: - Empty House Card
struct EmptyHouseCard: View {
    let nextReservation: Prenotazione?
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            VStack(spacing: 8) {
                Image(systemName: "house")
                    .font(.title)
                    .foregroundColor(.gray)
                
                Text("LIBERA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            
            // Next reservation info
            VStack(alignment: .leading, spacing: 6) {
                if let next = nextReservation {
                    Text("Prossimo ospite:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text(next.nomeOspite)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Check-in:")
                            .foregroundColor(.secondary)
                        Text(formatDate(next.dataCheckIn))
                            .fontWeight(.medium)
                    }
                    .font(.callout)
                } else {
                    Text("Nessuna prenotazione")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("La casa è disponibile")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let next = nextReservation {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("€\(String(format: "%.0f", next.prezzoTotale))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Prossimo ricavo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// MARK: - Daily Operation Card
struct DailyOperationCard: View {
    let title: String
    let guests: [Prenotazione]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text("\(guests.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.callout)
                .fontWeight(.medium)
            
            if let guest = guests.first {
                Text(guest.nomeOspite)
                    .font(.caption)
                    .foregroundColor(color)
                    .lineLimit(1)
            } else {
                Text("Nessuno")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
