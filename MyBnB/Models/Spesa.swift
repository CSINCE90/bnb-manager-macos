//
//  Spesa.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//modificata in data 01/09/25

import Foundation

struct Spesa: Identifiable, Codable {
    var id: UUID
    var strutturaId: UUID? = nil
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
    
    enum CodingKeys: String, CodingKey { case id, strutturaId, descrizione, importo, data, categoria }

    // Inizializzatore
    init(id: UUID = UUID(), strutturaId: UUID? = nil, descrizione: String, importo: Double, data: Date, categoria: CategoriaSpesa) {
        self.id = id
        self.strutturaId = strutturaId
        self.descrizione = descrizione
        self.importo = importo
        self.data = data
        self.categoria = categoria
    }
}
