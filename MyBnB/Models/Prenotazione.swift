// ===== FIX 1: Models/Prenotazione.swift (AGGIORNA CON @Published) =====

import SwiftUI

struct Prenotazione: Identifiable, Codable {
    var id: UUID
    var strutturaId: UUID? = nil
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
    
    enum CodingKeys: String, CodingKey { case id, strutturaId, nomeOspite, email, telefono, dataCheckIn, dataCheckOut, numeroOspiti, prezzoTotale, statoPrenotazione, note }

    // Inizializzatore (id di default per nuove istanze)
    init(id: UUID = UUID(), strutturaId: UUID? = nil, nomeOspite: String, email: String, telefono: String, dataCheckIn: Date, dataCheckOut: Date, numeroOspiti: Int, prezzoTotale: Double, statoPrenotazione: StatoPrenotazione, note: String) {
        self.id = id
        self.strutturaId = strutturaId
        self.nomeOspite = nomeOspite
        self.email = email
        self.telefono = telefono
        self.dataCheckIn = dataCheckIn
        self.dataCheckOut = dataCheckOut
        self.numeroOspiti = numeroOspiti
        self.prezzoTotale = prezzoTotale
        self.statoPrenotazione = statoPrenotazione
        self.note = note
    }
}
