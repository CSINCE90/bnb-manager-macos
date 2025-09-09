//
//  GestionaleViewModel+MovimentiFinanziari.swift
//  MyBnB
//
//  Estensione semplificata per gestire solo MovimentiFinanziari in Core Data
//

import Foundation
import SwiftUI
import CoreData

// MARK: - Extension per Movimenti Finanziari
extension GestionaleViewModel {
    
    // MARK: - Caricamento Movimenti da Core Data
    
    func loadMovimentoFinanziarioFromCoreData() {
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        
        do {
            let cdMovimenti = try context.fetch(request)
            var loadedMovimenti: [MovimentoFinanziario] = []
            
            for cd in cdMovimenti {
                if let movimento = convertToMovimentoFinanziario(from: cd) {
                    loadedMovimenti.append(movimento)
                }
            }
            
            if !loadedMovimenti.isEmpty {
                self.movimentiFinanziari = loadedMovimenti
                print("✅ Caricati \(loadedMovimenti.count) movimenti finanziari da Core Data")
            }
            
        } catch {
            print("❌ Errore caricamento movimenti finanziari: \(error)")
        }
    }
    
    // MARK: - Conversione da Core Data a Model
    
    private func convertToMovimentoFinanziario(from cdObject: NSManagedObject) -> MovimentoFinanziario? {
        guard let descrizione = cdObject.value(forKey: "descrizione") as? String,
              let importo = cdObject.value(forKey: "importo") as? Double,
              let data = cdObject.value(forKey: "data") as? Date,
              let tipoRaw = cdObject.value(forKey: "tipo") as? String,
              let categoriaRaw = cdObject.value(forKey: "categoria") as? String,
              let metodoPagamentoRaw = cdObject.value(forKey: "metodoPagamento") as? String else {
            return nil
        }

        let note = cdObject.value(forKey: "note") as? String ?? ""
        let prenotazioneId = cdObject.value(forKey: "prenotazioneId") as? UUID
        let updatedAt = cdObject.value(forKey: "updatedAt") as? Date ?? Date()
        let createdAt = cdObject.value(forKey: "createdAt") as? Date ?? Date()

        guard let tipo = MovimentoFinanziario.TipoMovimento(rawValue: tipoRaw),
              let categoria = MovimentoFinanziario.CategoriaMovimento(rawValue: categoriaRaw),
              let metodoPagamento = MovimentoFinanziario.MetodoPagamento(rawValue: metodoPagamentoRaw) else {
            return nil
        }

        return MovimentoFinanziario(
            descrizione: descrizione,
            importo: importo,
            data: data,
            tipo: tipo,
            categoria: categoria,
            metodoPagamento: metodoPagamento,
            note: note,
            prenotazioneId: prenotazioneId,
            updatedAt: updatedAt
            
        )
    }
    
    // MARK: - Salvataggio in Core Data
    
    func salvaMovimentoFinanziario(_ movimento: MovimentoFinanziario) {
        let context = CoreDataManager.shared.viewContext
        
        if saveMovimentoFinanziarioToCoreData(movimento, context: context) {
            do {
                try context.save()
                
                // Aggiorna l'array locale
                if let index = movimentiFinanziari.firstIndex(where: { $0.id == movimento.id }) {
                    movimentiFinanziari[index] = movimento
                } else {
                    movimentiFinanziari.append(movimento)
                    // Ordina per data (più recenti prima)
                    movimentiFinanziari.sort { $0.data > $1.data }
                }
                
                print("✅ Movimento finanziario salvato in Core Data")
                
                // Mantieni compatibilità con JSON
                salvaDati()
                
            } catch {
                print("❌ Errore salvataggio movimento finanziario: \(error)")
            }
        }
    }
    
    private func saveMovimentoFinanziarioToCoreData(_ movimento: MovimentoFinanziario, context: NSManagedObjectContext) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDMovimentoFinanziario", in: context) else {
            print("❌ Entità CDMovimentoFinanziario non trovata")
            return false
        }
        
        // Controlla se esiste già
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        fetchRequest.predicate = NSPredicate(format: "id == %@", movimento.id as CVarArg)
        
        do {
            let existingMovimenti = try context.fetch(fetchRequest)
            let cdMovimento = existingMovimenti.first ?? NSManagedObject(entity: entity, insertInto: context)
            
            cdMovimento.setValue(movimento.id, forKey: "id")
            cdMovimento.setValue(movimento.descrizione, forKey: "descrizione")
            cdMovimento.setValue(movimento.importo, forKey: "importo")
            cdMovimento.setValue(movimento.data, forKey: "data")
            cdMovimento.setValue(movimento.tipo.rawValue, forKey: "tipo")
            cdMovimento.setValue(movimento.categoria.rawValue, forKey: "categoria")
            cdMovimento.setValue(movimento.metodoPagamento.rawValue, forKey: "metodoPagamento")
            cdMovimento.setValue(movimento.note, forKey: "note")
            cdMovimento.setValue(Date(), forKey: "updatedAt")
            
            // Solo per i nuovi record
            if existingMovimenti.isEmpty {
                cdMovimento.setValue(movimento.createdAt, forKey: "createdAt")
            }
            
            return true
            
        } catch {
            print("❌ Errore controllo esistenza movimento: \(error)")
            return false
        }
    }
    
    // MARK: - Eliminazione
    
    func eliminaMovimentoFinanziario(_ movimento: MovimentoFinanziario) {
        let context = CoreDataManager.shared.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        fetchRequest.predicate = NSPredicate(format: "id == %@", movimento.id as CVarArg)
        
        do {
            let movimentiDaEliminare = try context.fetch(fetchRequest)
            
            for mov in movimentiDaEliminare {
                context.delete(mov)
            }
            
            try context.save()
            
            // Rimuovi dall'array locale
            movimentiFinanziari.removeAll { $0.id == movimento.id }
            
            print("✅ Movimento finanziario eliminato")
            
            // Mantieni compatibilità con JSON
            salvaDati()
            
        } catch {
            print("❌ Errore eliminazione movimento finanziario: \(error)")
        }
    }
    
    // MARK: - Migrazione e Pulizia
    
    func migrateMovimentiFinanziariToCoreData() {
        let context = CoreDataManager.shared.viewContext
        
        // Pulisci i dati esistenti
        cleanMovimentiFinanziariCoreData()
        
        // Migra Movimenti Finanziari
        var migratedMovimenti = 0
        for movimento in self.movimentiFinanziari {
            if saveMovimentoFinanziarioToCoreData(movimento, context: context) {
                migratedMovimenti += 1
            }
        }
        
        // Salva il contesto
        do {
            try context.save()
            print("✅ Migrazione movimenti finanziari completata: \(migratedMovimenti) movimenti")
        } catch {
            print("❌ Errore durante la migrazione movimenti finanziari: \(error)")
        }
    }
    
    private func cleanMovimentiFinanziariCoreData() {
        let context = CoreDataManager.shared.viewContext
        
        let deleteMovimenti = NSFetchRequest<NSFetchRequestResult>(entityName: "CDMovimentoFinanziario")
        let batchDeleteMovimenti = NSBatchDeleteRequest(fetchRequest: deleteMovimenti)
        
        do {
            try context.execute(batchDeleteMovimenti)
            print("🧹 Core Data movimenti finanziari pulito prima della migrazione")
        } catch {
            print("⚠️ Errore pulizia Core Data movimenti finanziari: \(error)")
        }
    }
    

    
    // MARK: - Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
