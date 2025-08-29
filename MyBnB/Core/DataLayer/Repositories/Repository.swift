//
//  Repository.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import Foundation
import CoreData

protocol Repository {
    associatedtype Entity
    func create(_ entity: Entity) async throws
    func read(id: UUID) async throws -> Entity?
    func update(_ entity: Entity) async throws
    func delete(id: UUID) async throws
    func getAll() async throws -> [Entity]
}

enum RepositoryError: LocalizedError {
    case entityNotFound
    case saveFailed
    case deleteFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound: return "Entità non trovata"
        case .saveFailed: return "Salvataggio fallito"
        case .deleteFailed: return "Eliminazione fallita"
        case .invalidData: return "Dati non validi"
        }
    }
}
