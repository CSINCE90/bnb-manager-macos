

//
//  GestionaleViewModel+Enhanced.swift
//  MyBnB
//
//  Estensione per aggiungere Core Data al ViewModel esistente
//  NOTA: Non modifica il codice esistente, aggiunge solo funzionalità
//

import Foundation
import SwiftUI
import CoreData

// MARK: - Core Data Extension
extension GestionaleViewModel {
    
    /// Abilita Core Data mantenendo la compatibilità con JSON
    func enableCoreData() {
        print("🔄 Inizializzazione Core Data...")
        
        // Controlla se Core Data è disponibile
        guard isCoreDataAvailable() else {
            print("⚠️ Core Data non disponibile, continuo con JSON")
            return
        }
        
        // Carica dati da Core Data
        loadFromCoreData()
        
        // Se Core Data è vuoto, migra i dati esistenti
        if isCoreDataEmpty() {
            print("📦 Core Data vuoto, migrazione dati esistenti...")
            migrateExistingDataToCoreData()
        } else {
            print("✅ Core Data già popolato con \(prenotazioni.count) prenotazioni")
        }
    }
    
    // MARK: - Verifica Core Data
    
    private func isCoreDataAvailable() -> Bool {
        // Verifica se il modello Core Data esiste
        guard let _ = NSManagedObjectModel.mergedModel(from: nil) else {
            return false
        }
        return true
    }
    
    private func isCoreDataEmpty() -> Bool {
        let context = CoreDataManager.shared.viewContext
        
        // Controlla prenotazioni
        let requestPren = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
        requestPren.fetchLimit = 1
        
        do {
            let count = try context.count(for: requestPren)
            return count == 0
        } catch {
            print("⚠️ Errore verifica Core Data: \(error)")
            return true
        }
    }
    
    // MARK: - Caricamento da Core Data
    
    private func loadFromCoreData() {
        loadPrenotazioniFromCoreData()
        loadSpeseFromCoreData()
    }
    
    private func loadPrenotazioniFromCoreData() {
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
        request.sortDescriptors = [NSSortDescriptor(key: "dataCheckIn", ascending: true)]
        
        do {
            let cdPrenotazioni = try context.fetch(request)
            var loadedPrenotazioni: [Prenotazione] = []
            
            for cd in cdPrenotazioni {
                if let prenotazione = convertToPrenotazione(from: cd) {
                    loadedPrenotazioni.append(prenotazione)
                }
            }
            
            if !loadedPrenotazioni.isEmpty {
                self.prenotazioni = loadedPrenotazioni
                print("✅ Caricate \(loadedPrenotazioni.count) prenotazioni da Core Data")
            }
            
        } catch {
            print("❌ Errore caricamento prenotazioni: \(error)")
        }
    }
    
    private func loadSpeseFromCoreData() {
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDSpesa")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        
        do {
            let cdSpese = try context.fetch(request)
            var loadedSpese: [Spesa] = []
            
            for cd in cdSpese {
                if let spesa = convertToSpesa(from: cd) {
                    loadedSpese.append(spesa)
                }
            }
            
            if !loadedSpese.isEmpty {
                self.spese = loadedSpese
                print("✅ Caricate \(loadedSpese.count) spese da Core Data")
            }
            
        } catch {
            print("❌ Errore caricamento spese: \(error)")
        }
    }
    
    
    // MARK: - Conversione Modelli
    
    private func convertToPrenotazione(from cdObject: NSManagedObject) -> Prenotazione? {
        guard let nomeOspite = cdObject.value(forKey: "nomeOspite") as? String,
              let email = cdObject.value(forKey: "email") as? String,
              let dataCheckIn = cdObject.value(forKey: "dataCheckIn") as? Date,
              let dataCheckOut = cdObject.value(forKey: "dataCheckOut") as? Date,
              let numeroOspiti = cdObject.value(forKey: "numeroOspiti") as? Int16,
              let prezzoTotale = cdObject.value(forKey: "prezzoTotale") as? Double,
              let stato = cdObject.value(forKey: "statoPrenotazione") as? String else {
            return nil
        }
        
        let telefono = cdObject.value(forKey: "telefono") as? String ?? ""
        let note = cdObject.value(forKey: "note") as? String ?? ""
        
        return Prenotazione(
            nomeOspite: nomeOspite,
            email: email,
            telefono: telefono,
            dataCheckIn: dataCheckIn,
            dataCheckOut: dataCheckOut,
            numeroOspiti: Int(numeroOspiti),
            prezzoTotale: prezzoTotale,
            statoPrenotazione: Prenotazione.StatoPrenotazione(rawValue: stato) ?? .inAttesa,
            note: note
        )
    }
    
    private func convertToSpesa(from cdObject: NSManagedObject) -> Spesa? {
        guard let descrizione = cdObject.value(forKey: "descrizione") as? String,
              let importo = cdObject.value(forKey: "importo") as? Double,
              let data = cdObject.value(forKey: "data") as? Date,
              let categoria = cdObject.value(forKey: "categoria") as? String else {
            return nil
        }
        
        return Spesa(
            descrizione: descrizione,
            importo: importo,
            data: data,
            categoria: Spesa.CategoriaSpesa(rawValue: categoria) ?? .altro
        )
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
             cdMovimento.setValue(movimento.prenotazioneId, forKey: "prenotazioneId")
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
     
     

    
    // MARK: - Migrazione a Core Data
    
    private func migrateExistingDataToCoreData() {
        let context = CoreDataManager.shared.viewContext
        
        // Pulisci Core Data prima della migrazione
        cleanCoreData()
        
        // Migra Prenotazioni
        var migratedPrenotazioni = 0
        for prenotazione in self.prenotazioni {
            if savePrenotazioneToCoreData(prenotazione, context: context) {
                migratedPrenotazioni += 1
            }
        }
        
        // Migra Spese
        var migratedSpese = 0
        for spesa in self.spese {
            if saveSpesaToCoreData(spesa, context: context) {
                migratedSpese += 1
            }
        }
        
                
 
        
        // Salva il contesto
        do {
            try context.save()
            print("✅ Migrazione completata:")
            print("   - \(migratedPrenotazioni) prenotazioni")
            print("   - \(migratedSpese) spese")
        } catch {
            print("❌ Errore durante la migrazione: \(error)")
        }
    }
    
    private func cleanCoreData() {
        let context = CoreDataManager.shared.viewContext
        
        // Elimina prenotazioni esistenti
        let deletePren = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPrenotazione")
        let batchDeletePren = NSBatchDeleteRequest(fetchRequest: deletePren)
        
        // Elimina spese esistenti
        let deleteSpese = NSFetchRequest<NSFetchRequestResult>(entityName: "CDSpesa")
        let batchDeleteSpese = NSBatchDeleteRequest(fetchRequest: deleteSpese)
        
        // Elimina movimenti esistenti
        let deleteMovimenti = NSFetchRequest<NSFetchRequestResult>(entityName: "CDMovimentoFinanziario")
        let batchDeleteMovimenti = NSBatchDeleteRequest(fetchRequest: deleteMovimenti)
               
        // Elimina bonifici esistenti
        let deleteBonifici = NSFetchRequest<NSFetchRequestResult>(entityName: "CDBonifico")
        let batchDeleteBonifici = NSBatchDeleteRequest(fetchRequest: deleteBonifici)
               
        
        do {
            try context.execute(batchDeletePren)
            try context.execute(batchDeleteSpese)
            try context.execute(batchDeleteMovimenti)
            try context.execute(batchDeleteBonifici)
            print("🧹 Core Data pulito prima della migrazione")
        } catch {
            print("⚠️ Errore pulizia Core Data: \(error)")
        }
    }
    
    // MARK: - Salvataggio in Core Data
    
    private func savePrenotazioneToCoreData(_ prenotazione: Prenotazione, context: NSManagedObjectContext) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDPrenotazione", in: context) else {
            print("❌ Entità CDPrenotazione non trovata")
            return false
        }
        
        let cdPrenotazione = NSManagedObject(entity: entity, insertInto: context)
        
        cdPrenotazione.setValue(prenotazione.id, forKey: "id")
        cdPrenotazione.setValue(prenotazione.nomeOspite, forKey: "nomeOspite")
        cdPrenotazione.setValue(prenotazione.email, forKey: "email")
        cdPrenotazione.setValue(prenotazione.telefono, forKey: "telefono")
        cdPrenotazione.setValue(prenotazione.dataCheckIn, forKey: "dataCheckIn")
        cdPrenotazione.setValue(prenotazione.dataCheckOut, forKey: "dataCheckOut")
        cdPrenotazione.setValue(Int16(prenotazione.numeroOspiti), forKey: "numeroOspiti")
        cdPrenotazione.setValue(prenotazione.prezzoTotale, forKey: "prezzoTotale")
        cdPrenotazione.setValue(prenotazione.statoPrenotazione.rawValue, forKey: "statoPrenotazione")
        cdPrenotazione.setValue(prenotazione.note, forKey: "note")
        cdPrenotazione.setValue(Date(), forKey: "createdAt")
        cdPrenotazione.setValue(Date(), forKey: "updatedAt")
        
        return true
    }
    
    private func saveSpesaToCoreData(_ spesa: Spesa, context: NSManagedObjectContext) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDSpesa", in: context) else {
            print("❌ Entità CDSpesa non trovata")
            return false
        }
        
        let cdSpesa = NSManagedObject(entity: entity, insertInto: context)
        
        cdSpesa.setValue(spesa.id, forKey: "id")
        cdSpesa.setValue(spesa.descrizione, forKey: "descrizione")
        cdSpesa.setValue(spesa.importo, forKey: "importo")
        cdSpesa.setValue(spesa.data, forKey: "data")
        cdSpesa.setValue(spesa.categoria.rawValue, forKey: "categoria")
        cdSpesa.setValue(Date(), forKey: "createdAt")
        
        return true
    }
    
    // MARK: - Override Metodi Esistenti (Opzionale)
    
    /// Salva sia in JSON che in Core Data per mantenere compatibilità
    func saveToBothSystems() {
        // Salva in JSON (metodo esistente)
        salvaDati()
        
        // Salva anche in Core Data se disponibile
        if isCoreDataAvailable() {
            syncToCoreData()
        }
    }
    
    private func syncToCoreData() {
        let context = CoreDataManager.shared.viewContext
        
        // Pulisci e risincronizza
        cleanCoreData()
        
        // Salva tutte le prenotazioni
        for prenotazione in prenotazioni {
            _ = savePrenotazioneToCoreData(prenotazione, context: context)
        }
        
        // Salva tutte le spese
        for spesa in spese {
            _ = saveSpesaToCoreData(spesa, context: context)
        }
        
        
        // Commit
        do {
            try context.save()
            print("✅ Sincronizzazione Core Data completata")
        } catch {
            print("❌ Errore sincronizzazione: \(error)")
        }
    }
    
    // MARK: - Metodi Helper Aggiuntivi
    
    /// Esporta dati da Core Data in formato JSON
    func exportCoreDataToJSON() -> Data? {
        let exportData: [String: Any] = [
            "prenotazioni": prenotazioni.map { prenotazione in
                [
                    "id": prenotazione.id.uuidString,
                    "nomeOspite": prenotazione.nomeOspite,
                    "email": prenotazione.email,
                    "telefono": prenotazione.telefono,
                    "dataCheckIn": ISO8601DateFormatter().string(from: prenotazione.dataCheckIn),
                    "dataCheckOut": ISO8601DateFormatter().string(from: prenotazione.dataCheckOut),
                    "numeroOspiti": prenotazione.numeroOspiti,
                    "prezzoTotale": prenotazione.prezzoTotale,
                    "stato": prenotazione.statoPrenotazione.rawValue,
                    "note": prenotazione.note
                ]
            },
            "spese": spese.map { spesa in
                [
                    "id": spesa.id.uuidString,
                    "descrizione": spesa.descrizione,
                    "importo": spesa.importo,
                    "data": ISO8601DateFormatter().string(from: spesa.data),
                    "categoria": spesa.categoria.rawValue
                ]
            },
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "version": "2.0"
        ]
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("❌ Errore export JSON: \(error)")
            return nil
        }
    }
    
    /// Verifica integrità dei dati
    func verifyDataIntegrity() {
        print("\n📊 Verifica Integrità Dati:")
        print("   JSON: \(prenotazioni.count) prenotazioni, \(spese.count) spese")
        
        if isCoreDataAvailable() {
            let context = CoreDataManager.shared.viewContext
            
            do {
                let prenRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
                let prenCount = try context.count(for: prenRequest)
                
                let speseRequest = NSFetchRequest<NSManagedObject>(entityName: "CDSpesa")
                let speseCount = try context.count(for: speseRequest)
                
                print("   Core Data: \(prenCount) prenotazioni, \(speseCount) spese")
                
                if prenCount != prenotazioni.count || speseCount != spese.count {
                    print("   ⚠️ Disallineamento dati - risincronizzazione necessaria")
                    syncToCoreData()
                } else {
                    print("   ✅ Dati allineati")
                }
            } catch {
                print("   ❌ Errore verifica: \(error)")
            }
        }
    }
} 
