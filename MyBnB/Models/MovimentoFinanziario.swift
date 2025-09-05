//
//  MovimentoFinanziario.swift
//  MyBnB
//
//  Created by Francesco Chifari on 02/09/25.
//

import Foundation
import SwiftUI

// MARK: - MovimentoFinanziario
struct MovimentoFinanziario: Identifiable, Codable {
    let id = UUID()
    var descrizione: String
    var importo: Double
    var data: Date
    var tipo: TipoMovimento
    var categoria: CategoriaMovimento
    var metodoPagamento: MetodoPagamento
    var note: String = ""
    var prenotazioneId: UUID?
    var updatedAt = Date()
    let createdAt = Date()
    
    enum TipoMovimento: String, CaseIterable, Codable {
        case entrata = "Entrata"
        case uscita = "Uscita"
        
        var icona: String {
            switch self {
            case .entrata: return "arrow.up.circle.fill"
            case .uscita: return "arrow.down.circle.fill"
            }
        }
        
        var colore: Color {
            switch self {
            case .entrata: return .green
            case .uscita: return .red
            }
        }
    }
    
    enum CategoriaMovimento: String, CaseIterable, Codable {
        case prenotazioni = "Prenotazioni"
        case altreEntrate = "Altre Entrate"
        case altreSpese = "Altre Spese"
        case manutenzione = "Manutenzione"
        case pulizie = "Pulizie"
        case utenze = "Utenze"
        
        var icona: String {
            switch self {
            case .prenotazioni: return "bed.double.fill"
            case .altreEntrate: return "plus.circle.fill"
            case .altreSpese: return "minus.circle.fill"
            case .manutenzione: return "wrench.fill"
            case .pulizie: return "sparkles"
            case .utenze: return "bolt.fill"
            }
        }
        
        var colore: Color {
            switch self {
            case .prenotazioni: return .blue
            case .altreEntrate: return .green
            case .altreSpese: return .red
            case .manutenzione: return .orange
            case .pulizie: return .purple
            case .utenze: return .yellow
            }
        }
        
        var isEntrata: Bool {
            switch self {
            case .prenotazioni, .altreEntrate: return true
            case .altreSpese, .manutenzione, .pulizie, .utenze: return false
            }
        }
    }
    
    enum MetodoPagamento: String, CaseIterable, Codable {
        case contanti = "Contanti"
        case bonifico = "Bonifico"
        case carta = "Carta"
        case bookingcom = "Booking.com"
        
        var icona: String {
            switch self {
            case .contanti: return "banknote.fill"
            case .bonifico: return "building.columns.fill"
            case .carta: return "creditcard.fill"
            case .bookingcom: return "globe"
            }
        }
    }
}
// MARK: - Bonifico
struct Bonifico: Identifiable, Codable {
    let id = UUID()
    var importo: Double
    var data: Date
    var dataValuta: Date?
    var ordinante: String
    var beneficiario: String
    var causale: String
    var cro: String
    var iban: String
    var banca: String
    var tipo: TipoBonifico
    var stato: StatoBonifico = .inAttesa
    var commissioni: Double = 0.0
    var note: String = ""
    var movimentoId: UUID?
    var updatedAt = Date()
    let createdAt = Date()
    
    var importoNetto: Double {
        return importo - commissioni
    }
    
    enum TipoBonifico: String, CaseIterable, Codable {
        case ricevuto = "Ricevuto"
        case inviato = "Inviato"
        
        var colore: Color {
            switch self {
            case .ricevuto: return .green
            case .inviato: return .red
            }
        }
    }
    
    enum StatoBonifico: String, CaseIterable, Codable {
        case inAttesa = "In Attesa"
        case elaborazione = "In Elaborazione"
        case completato = "Completato"
        case rifiutato = "Rifiutato"
        
        var icona: String {
            switch self {
            case .inAttesa: return "clock.fill"
            case .elaborazione: return "arrow.clockwise"
            case .completato: return "checkmark.circle.fill"
            case .rifiutato: return "xmark.circle.fill"
            }
        }
        
        var colore: Color {
            switch self {
            case .inAttesa: return .orange
            case .elaborazione: return .blue
            case .completato: return .green
            case .rifiutato: return .red
            }
        }
    }
}
// MARK: - RiepilogoMensile
struct RiepilogoMensile: Identifiable, Codable {
    let id = UUID()
    var mese: Int
    var anno: Int
    var entratePrenotazioni: Double
    var altreEntrate: Double
    var totaleEntrate: Double
    var totaleUscite: Double
    var saldoMensile: Double
    var bonificiRicevuti: Double
    var bonificiInviati: Double
    var numeroPrenotazioni: Int
    var numeroMovimenti: Int
    var numeroBonifici: Int
    
    var nomeMessaggio: String {
        let monthNames = [
            "Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno",
            "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"
        ]
        
        let monthName = (mese >= 1 && mese <= 12) ? monthNames[mese - 1] : "Mese \(mese)"
        return "\(monthName) \(anno)"
    }
    
    var margineProfit: Double {
        guard totaleEntrate > 0 else { return 0 }
        return (saldoMensile / totaleEntrate) * 100
    }
}
