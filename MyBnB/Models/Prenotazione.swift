//
//  Prenotazione.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct Prenotazione: Identifiable, Codable {
    let id = UUID()
    var nomeOspite: String
    var email: String
    var telefono: String
    var dataCheckIn: Date
    var dataCheckOut: Date
    var numeroOspiti: Int
    var prezzoTotale: Double
    var statoPrenotazione: StatoPrenotazione
    var note: String
    
    enum StatoPrenotazione: String, CaseIterable, Codable {
        case confermata = "Confermata"
        case inAttesa = "In Attesa"
        case cancellata = "Cancellata"
        case completata = "Completata"
        
        var colore: Color {
            switch self {
            case .confermata: return .green
            case .inAttesa: return .orange
            case .cancellata: return .red
            case .completata: return .blue
            }
        }
    }
    
    var numeroNotti: Int {
        Calendar.current.dateComponents([.day], from: dataCheckIn, to: dataCheckOut).day ?? 0
    }
}
