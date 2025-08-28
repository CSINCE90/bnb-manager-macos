//
//  GestionaleViewModel.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//


import Foundation
import SwiftUI

class GestionaleViewModel: ObservableObject {
    @Published var prenotazioni: [Prenotazione] = []
    @Published var spese: [Spesa] = []
    
    init() {
        caricaDati()
    }
    
    var entrateTotali: Double {
        prenotazioni
            .filter { $0.statoPrenotazione == .confermata || $0.statoPrenotazione == .completata }
            .reduce(0) { $0 + $1.prezzoTotale }
    }
    
    var speseTotali: Double {
        spese.reduce(0) { $0 + $1.importo }
    }
    
    var profittoNetto: Double {
        entrateTotali - speseTotali
    }
    
    var prenotazioniAttive: [Prenotazione] {
        prenotazioni.filter { $0.statoPrenotazione == .confermata || $0.statoPrenotazione == .inAttesa }
            .sorted { $0.dataCheckIn < $1.dataCheckIn }
    }
    
    func aggiungiPrenotazione(_ prenotazione: Prenotazione) {
        prenotazioni.append(prenotazione)
        salvaDati()
    }
    
    func eliminaPrenotazione(at offsets: IndexSet) {
        prenotazioni.remove(atOffsets: offsets)
        salvaDati()
    }
    
    func aggiungiSpesa(_ spesa: Spesa) {
        spese.append(spesa)
        salvaDati()
    }
    
    func eliminaSpesa(at offsets: IndexSet) {
        spese.remove(atOffsets: offsets)
        salvaDati()
    }
    
    // MARK: - Persistenza Dati
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func salvaDati() {
        let encoder = JSONEncoder()
        
        // Salva prenotazioni
        if let encoded = try? encoder.encode(prenotazioni) {
            let url = getDocumentsDirectory().appendingPathComponent("prenotazioni.json")
            try? encoded.write(to: url)
        }
        
        // Salva spese
        if let encoded = try? encoder.encode(spese) {
            let url = getDocumentsDirectory().appendingPathComponent("spese.json")
            try? encoded.write(to: url)
        }
    }
    
    private func caricaDati() {
        let decoder = JSONDecoder()
        
        // Carica prenotazioni
        let prenotazioniURL = getDocumentsDirectory().appendingPathComponent("prenotazioni.json")
        if let data = try? Data(contentsOf: prenotazioniURL),
           let decoded = try? decoder.decode([Prenotazione].self, from: data) {
            prenotazioni = decoded
        }
        
        // Carica spese
        let speseURL = getDocumentsDirectory().appendingPathComponent("spese.json")
        if let data = try? Data(contentsOf: speseURL),
           let decoded = try? decoder.decode([Spesa].self, from: data) {
            spese = decoded
        }
    }
}
