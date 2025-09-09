//
//  SpesaRepository.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class SpesaRepository: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var spese: [Spesa] = []
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
        Task {
            await loadSpese()
        }
    }
    
    func create(_ entity: Spesa) async throws {
        let cdSpesa = CDSpesa(context: context)
        cdSpesa.id = entity.id
        cdSpesa.descrizione = entity.descrizione
        cdSpesa.importo = entity.importo
        cdSpesa.data = entity.data
        cdSpesa.categoria = entity.categoria.rawValue
        cdSpesa.createdAt = Date()
        
        do {
            try context.save()
            await loadSpese()
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    func delete(id: UUID) async throws {
        let request: NSFetchRequest<CDSpesa> = CDSpesa.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let cdSpesa = try context.fetch(request).first else {
            throw RepositoryError.entityNotFound
        }
        
        context.delete(cdSpesa)
        
        do {
            try context.save()
            await loadSpese()
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
    
    func getAll() async throws -> [Spesa] {
        let request: NSFetchRequest<CDSpesa> = CDSpesa.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        
        let results = try context.fetch(request)
        return results.map { cdSpesa in
            Spesa(
                id: cdSpesa.id ?? UUID(),
                descrizione: cdSpesa.descrizione ?? "",
                importo: cdSpesa.importo,
                data: cdSpesa.data ?? Date(),
                categoria: Spesa.CategoriaSpesa(rawValue: cdSpesa.categoria ?? "altro") ?? .altro
            )
        }
    }
    
    private func loadSpese() async {
        do {
            spese = try await getAll()
        } catch {
            print("Error loading spese: \(error)")
        }
    }
}
