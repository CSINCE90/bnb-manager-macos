//
//  PrenotazioneRepository.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class PrenotazioneRepository: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var prenotazioni: [Prenotazione] = []
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
        Task {
            await loadPrenotazioni()
        }
    }
    
    func create(_ entity: Prenotazione) async throws {
        let cdPrenotazione = CDPrenotazione(context: context)
        mapToCore(entity, cdPrenotazione)
        
        do {
            try context.save()
            await loadPrenotazioni()
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    func update(_ entity: Prenotazione) async throws {
        let request: NSFetchRequest<CDPrenotazione> = CDPrenotazione.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entity.id as CVarArg)
        
        guard let cdPrenotazione = try context.fetch(request).first else {
            throw RepositoryError.entityNotFound
        }
        
        mapToCore(entity, cdPrenotazione)
        
        do {
            try context.save()
            await loadPrenotazioni()
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    func delete(id: UUID) async throws {
        let request: NSFetchRequest<CDPrenotazione> = CDPrenotazione.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let cdPrenotazione = try context.fetch(request).first else {
            throw RepositoryError.entityNotFound
        }
        
        context.delete(cdPrenotazione)
        
        do {
            try context.save()
            await loadPrenotazioni()
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
    
    func getAll() async throws -> [Prenotazione] {
        let request: NSFetchRequest<CDPrenotazione> = CDPrenotazione.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dataCheckIn", ascending: true)]
        
        let results = try context.fetch(request)
        return results.map(mapFromCore)
    }
    
    func getActiveBookings() async throws -> [Prenotazione] {
        let request: NSFetchRequest<CDPrenotazione> = CDPrenotazione.fetchRequest()
        request.predicate = NSPredicate(format: "statoPrenotazione IN %@",
                                       ["confermata", "inAttesa"])
        request.sortDescriptors = [NSSortDescriptor(key: "dataCheckIn", ascending: true)]
        
        let results = try context.fetch(request)
        return results.map(mapFromCore)
    }
    
    private func loadPrenotazioni() async {
        do {
            prenotazioni = try await getAll()
        } catch {
            print("Error loading prenotazioni: \(error)")
        }
    }
    
    private func mapToCore(_ entity: Prenotazione, _ cdEntity: CDPrenotazione) {
        cdEntity.id = entity.id
        cdEntity.nomeOspite = entity.nomeOspite
        cdEntity.email = entity.email
        cdEntity.telefono = entity.telefono
        cdEntity.dataCheckIn = entity.dataCheckIn
        cdEntity.dataCheckOut = entity.dataCheckOut
        cdEntity.numeroOspiti = Int16(entity.numeroOspiti)
        cdEntity.prezzoTotale = entity.prezzoTotale
        cdEntity.statoPrenotazione = entity.statoPrenotazione.rawValue
        cdEntity.note = entity.note
        cdEntity.createdAt = cdEntity.createdAt ?? Date()
        cdEntity.updatedAt = Date()
    }
    
    private func mapFromCore(_ cdEntity: CDPrenotazione) -> Prenotazione {
        Prenotazione(
            id: cdEntity.id ?? UUID(),
            nomeOspite: cdEntity.nomeOspite ?? "",
            email: cdEntity.email ?? "",
            telefono: cdEntity.telefono ?? "",
            dataCheckIn: cdEntity.dataCheckIn ?? Date(),
            dataCheckOut: cdEntity.dataCheckOut ?? Date(),
            numeroOspiti: Int(cdEntity.numeroOspiti),
            prezzoTotale: cdEntity.prezzoTotale,
            statoPrenotazione: Prenotazione.StatoPrenotazione(
                rawValue: cdEntity.statoPrenotazione ?? "inAttesa"
            ) ?? .inAttesa,
            note: cdEntity.note ?? ""
        )
    }
}
