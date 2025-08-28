//
//  PrenotazioneCardCompatta.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI


struct PrenotazioneCardCompatta: View {
    let prenotazione: Prenotazione
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prenotazione.nomeOspite)
                    .fontWeight(.medium)
                Text("Check-in: \(formattaData(prenotazione.dataCheckIn))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(String(format: "€%.2f", prenotazione.prezzoTotale))
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    func formattaData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}
