//
//  OccupancySettingsView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE MANCANTE 6: Dashboard/Components/OccupancySettingsView.swift =====

import SwiftUI

struct OccupancySettingsView: View {
    @Binding var totalBeds: Int
    @Binding var accommodationType: String
    @Environment(\.dismiss) private var dismiss
    
    let accommodationTypes = ["B&B", "Casa Vacanze", "Affittacamere", "Guest House", "Ostello", "Appartamento"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Impostazioni Struttura")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Section("Tipo di Struttura") {
                    Picker("Tipo", selection: $accommodationType) {
                        ForEach(accommodationTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Capacità") {
                    HStack {
                        Text("Posti Letto Totali")
                        Spacer()
                        Stepper("\(totalBeds)", value: $totalBeds, in: 1...20)
                    }
                    
                    Text("Imposta il numero totale di posti letto disponibili nella tua struttura")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Anteprima") {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.blue)
                        Text("\(totalBeds) posti letto in \(accommodationType)")
                    }
                }
            }
            .frame(height: 250)
            
            HStack {
                Button("Annulla") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Salva") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
