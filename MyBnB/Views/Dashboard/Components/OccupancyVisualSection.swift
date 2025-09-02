//
//  OccupancyVisualSection.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

import SwiftUI

struct OccupancyVisualSection: View {
    @ObservedObject var viewModel: GestionaleViewModel
    
    @AppStorage("totalBeds") private var totalBeds = 4
    @AppStorage("accommodationType") private var accommodationType = "B&B"
    @State private var showingSettings = false
    
    var occupiedBeds: Int {
        let today = Date()
        return viewModel.prenotazioniAttive
            .filter { prenotazione in
                prenotazione.dataCheckIn <= today && prenotazione.dataCheckOut >= today
            }
            .reduce(0) { $0 + $1.numeroOspiti }
    }
    
    var availableBeds: Int {
        max(totalBeds - occupiedBeds, 0)
    }
    
    var occupancyRate: Double {
        guard totalBeds > 0 else { return 0 }
        return (Double(occupiedBeds) / Double(totalBeds)) * 100
    }
    
    var occupancyColor: Color {
        switch occupancyRate {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con impostazioni
            HStack {
                Text("Stato Occupazione")
                    .font(.headline)
                
                Spacer()
                
                // Badge con tipo struttura
                Text(accommodationType)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                
                // Bottone impostazioni
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(occupancyRate))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(occupancyColor)
            }
            
            HStack(spacing: 20) {
                // Grafico circolare
                ZStack {
                    Circle()
                        .stroke(occupancyColor.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: occupancyRate / 100)
                        .stroke(occupancyColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: occupancyRate)
                    
                    VStack(spacing: 2) {
                        Text("\(occupiedBeds)/\(totalBeds)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("posti letto")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Statistiche dettagliate
                VStack(alignment: .leading, spacing: 12) {
                    StatRowItem(
                        label: "Check-in Oggi",
                        value: "\(todayCheckIns()) ospiti",
                        color: .green
                    )
                    
                    StatRowItem(
                        label: "Check-out Oggi",
                        value: "\(todayCheckOuts()) ospiti",
                        color: .orange
                    )
                    
                    StatRowItem(
                        label: "Posti Disponibili",
                        value: "\(availableBeds)",
                        color: .blue
                    )
                }
                
                Spacer()
                
                // Visual dei posti letto
                VStack(alignment: .leading, spacing: 8) {
                    Text("Situazione Posti")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 30))
                    ], spacing: 8) {
                        ForEach(0..<totalBeds, id: \.self) { index in
                            Image(systemName: index < occupiedBeds ? "bed.double.fill" : "bed.double")
                                .font(.title2)
                                .foregroundColor(index < occupiedBeds ? occupancyColor : .gray.opacity(0.3))
                        }
                    }
                    .frame(maxWidth: 150)
                    
                    if occupancyRate >= 100 {
                        Text("Completo!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    } else if availableBeds == 1 {
                        Text("Ultimo posto!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .sheet(isPresented: $showingSettings) {
            OccupancySettingsView(totalBeds: $totalBeds, accommodationType: $accommodationType)
        }
    }
    
    // Calcola ospiti in check-in oggi
    private func todayCheckIns() -> Int {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni
            .filter { calendar.isDate($0.dataCheckIn, inSameDayAs: today) }
            .reduce(0) { $0 + $1.numeroOspiti }
    }
    
    // Calcola ospiti in check-out oggi
    private func todayCheckOuts() -> Int {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni
            .filter { calendar.isDate($0.dataCheckOut, inSameDayAs: today) }
            .reduce(0) { $0 + $1.numeroOspiti }
    }
}

struct StatRowItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
        }
    }
}
