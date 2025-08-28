//
//  PrenotazioniRow.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//
import SwiftUI

struct PrenotazioneRow: View {
    let prenotazione: Prenotazione
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(prenotazione.nomeOspite)
                    .font(.headline)
                
                Spacer()
                
                Text(prenotazione.statoPrenotazione.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(prenotazione.statoPrenotazione.colore.opacity(0.2))
                    .foregroundColor(prenotazione.statoPrenotazione.colore)
                    .cornerRadius(5)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text("\(formattaData(prenotazione.dataCheckIn)) - \(formattaData(prenotazione.dataCheckOut))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text("\(prenotazione.numeroOspiti) ospiti • \(prenotazione.numeroNotti) notti")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: "€%.2f", prenotazione.prezzoTotale))
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 5)
    }
    
    func formattaData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}
