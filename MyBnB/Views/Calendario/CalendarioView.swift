//
//  CalendarioView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct CalendarioView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var selectedDate = Date()
    
    var prenotazioniDelGiorno: [Prenotazione] {
        viewModel.prenotazioni.filter { prenotazione in
            let calendar = Calendar.current
            return calendar.isDate(prenotazione.dataCheckIn, inSameDayAs: selectedDate) ||
            calendar.isDate(prenotazione.dataCheckOut, inSameDayAs: selectedDate) ||
            (prenotazione.dataCheckIn <= selectedDate && prenotazione.dataCheckOut >= selectedDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Seleziona Data",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                List(prenotazioniDelGiorno) { prenotazione in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(prenotazione.nomeOspite)
                            .font(.headline)
                        
                        if Calendar.current.isDate(prenotazione.dataCheckIn, inSameDayAs: selectedDate) {
                            Label("Check-in", systemImage: "arrow.right.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        if Calendar.current.isDate(prenotazione.dataCheckOut, inSameDayAs: selectedDate) {
                            Label("Check-out", systemImage: "arrow.left.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        
                        if !Calendar.current.isDate(prenotazione.dataCheckIn, inSameDayAs: selectedDate) &&
                            !Calendar.current.isDate(prenotazione.dataCheckOut, inSameDayAs: selectedDate) {
                            Label("In soggiorno", systemImage: "house.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Text("\(prenotazione.numeroOspiti) ospiti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
                
                if prenotazioniDelGiorno.isEmpty {
                    Text("Nessuna prenotazione per questa data")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Calendario")
        }
    }
}
