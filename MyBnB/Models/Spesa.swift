//
//  Spesa.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import Foundation

struct Spesa: Identifiable, Codable {
    let id = UUID()
    var descrizione: String
    var importo: Double
    var data: Date
    var categoria: CategoriaSpesa
    
    enum CategoriaSpesa: String, CaseIterable, Codable {
        case pulizie = "Pulizie"
        case manutenzione = "Manutenzione"
        case utenze = "Utenze"
        case tasse = "Tasse"
        case altro = "Altro"
    }
}
