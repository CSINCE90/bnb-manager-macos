//
//  GestionaleViewModel.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//  Modificato per usare SOLO Core Data (eliminato sistema JSON)
//

import Foundation
import SwiftUI
import CoreData

class GestionaleViewModel: ObservableObject {
    @Published var prenotazioni: [Prenotazione] = []
    @Published var spese: [Spesa] = []
    @Published var movimentiFinanziari: [MovimentoFinanziario] = []
    
    init() {
        caricaDatiDaCoreData()
        // Migrazione una tantum da JSON se necessario (commenta dopo la prima esecuzione)
        // migraDaJSONUnaVolta()
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
    
    // MARK: - Gestione Prenotazioni
    
    func aggiungiPrenotazione(_ prenotazione: Prenotazione) {
        salvaPrenotazione(prenotazione)
    }
    
    func modificaPrenotazione(_ prenotazione: Prenotazione) {
        salvaPrenotazione(prenotazione) // Stessa logica, Core Data gestisce update/insert
    }
    
    func eliminaPrenotazione(at offsets: IndexSet) {
        for index in offsets {
            let prenotazione = prenotazioni[index]
            eliminaPrenotazioneDaCoreData(prenotazione)
        }
    }
    
    func eliminaPrenotazione(_ prenotazione: Prenotazione) {
        eliminaPrenotazioneDaCoreData(prenotazione)
    }
    
    // MARK: - Gestione Spese
    
    func aggiungiSpesa(_ spesa: Spesa) {
        salvaSpesa(spesa)
    }
    
    func modificaSpesa(_ spesa: Spesa) {
        salvaSpesa(spesa) // Stessa logica, Core Data gestisce update/insert
    }
    
    func eliminaSpesa(at offsets: IndexSet) {
        for index in offsets {
            let spesa = spese[index]
            eliminaSpesaDaCoreData(spesa)
        }
    }
    
    func eliminaSpesa(_ spesa: Spesa) {
        eliminaSpesaDaCoreData(spesa)
    }
    
    // MARK: - Caricamento da Core Data
    
        func caricaDatiDaCoreData() {
        caricaPrenotazioniDaCoreData()
        caricaSpeseDaCoreData()
        caricaMovimentiFinanziariDaCoreData()
    }
    
    private func caricaPrenotazioniDaCoreData() {
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
        request.sortDescriptors = [NSSortDescriptor(key: "dataCheckIn", ascending: true)]
        if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
            request.predicate = NSPredicate(format: "strutturaId == %@ OR strutturaId == nil", activeId as CVarArg)
        }
        request.fetchBatchSize = 100
        
        do {
            let cdPrenotazioni = try context.fetch(request)
            var loadedPrenotazioni: [Prenotazione] = []
            
            for cd in cdPrenotazioni {
                if let prenotazione = convertToPrenotazione(from: cd) {
                    loadedPrenotazioni.append(prenotazione)
                }
            }
            
            DispatchQueue.main.async {
                self.prenotazioni = loadedPrenotazioni
            }
            
            print("✅ Caricate \(loadedPrenotazioni.count) prenotazioni da Core Data")
            
        } catch {
            print("❌ Errore caricamento prenotazioni: \(error)")
        }
    }
    
    private func caricaSpeseDaCoreData() {
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDSpesa")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
            request.predicate = NSPredicate(format: "strutturaId == %@ OR strutturaId == nil", activeId as CVarArg)
        }
        request.fetchBatchSize = 100
        
        do {
            let cdSpese = try context.fetch(request)
            var loadedSpese: [Spesa] = []
            
            for cd in cdSpese {
                if let spesa = convertToSpesa(from: cd) {
                    loadedSpese.append(spesa)
                }
            }
            
            DispatchQueue.main.async {
                self.spese = loadedSpese
            }
            
            print("✅ Caricate \(loadedSpese.count) spese da Core Data")
            
        } catch {
            print("❌ Errore caricamento spese: \(error)")
        }
    }
    
    func caricaMovimentiFinanziariDaCoreData() {
        let context = CoreDataManager.shared.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
            request.predicate = NSPredicate(format: "strutturaId == %@ OR strutturaId == nil", activeId as CVarArg)
        }
        request.fetchBatchSize = 200
        
        do {
            let cdMovimenti = try context.fetch(request)
            var loadedMovimenti: [MovimentoFinanziario] = []
            
            for cd in cdMovimenti {
                if let movimento = convertToMovimentoFinanziario(from: cd) {
                    loadedMovimenti.append(movimento)
                }
            }
            
            DispatchQueue.main.async {
                self.movimentiFinanziari = loadedMovimenti
            }
            
            print("✅ Caricati \(loadedMovimenti.count) movimenti finanziari da Core Data")
            
        } catch {
            print("❌ Errore caricamento movimenti finanziari: \(error)")
        }
    }
    
    // MARK: - Salvataggio in Core Data
    
    func salvaPrenotazione(_ prenotazione: Prenotazione) {
        let context = CoreDataManager.shared.viewContext
        
        if salvaPrenotazioneInCoreData(prenotazione, context: context) {
            do {
                try context.save()
                
                // Aggiorna l'array locale
                DispatchQueue.main.async {
                    if let index = self.prenotazioni.firstIndex(where: { $0.id == prenotazione.id }) {
                        self.prenotazioni[index] = prenotazione
                    } else {
                        self.prenotazioni.append(prenotazione)
                        self.prenotazioni.sort { $0.dataCheckIn < $1.dataCheckIn }
                    }
                }
                
                print("✅ Prenotazione salvata in Core Data")
                
            } catch {
                print("❌ Errore salvataggio prenotazione: \(error)")
            }
        }
    }
    
    func salvaSpesa(_ spesa: Spesa) {
        let context = CoreDataManager.shared.viewContext
        
        if salvaSpesaInCoreData(spesa, context: context) {
            do {
                try context.save()
                
                // Aggiorna l'array locale
                DispatchQueue.main.async {
                    if let index = self.spese.firstIndex(where: { $0.id == spesa.id }) {
                        self.spese[index] = spesa
                    } else {
                        self.spese.append(spesa)
                        self.spese.sort { $0.data > $1.data }
                    }
                }
                
                print("✅ Spesa salvata in Core Data")
                
            } catch {
                print("❌ Errore salvataggio spesa: \(error)")
            }
        }
    }
    
    // MARK: - Eliminazione da Core Data
    
    private func eliminaPrenotazioneDaCoreData(_ prenotazione: Prenotazione) {
        let context = CoreDataManager.shared.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
        fetchRequest.predicate = NSPredicate(format: "id == %@", prenotazione.id as CVarArg)
        
        do {
            let prenotazioniDaEliminare = try context.fetch(fetchRequest)
            
            for pren in prenotazioniDaEliminare {
                context.delete(pren)
            }
            
            try context.save()
            
            // Rimuovi dall'array locale
            DispatchQueue.main.async {
                self.prenotazioni.removeAll { $0.id == prenotazione.id }
            }
            
            print("✅ Prenotazione eliminata")
            
        } catch {
            print("❌ Errore eliminazione prenotazione: \(error)")
        }
    }
    
    private func eliminaSpesaDaCoreData(_ spesa: Spesa) {
        let context = CoreDataManager.shared.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDSpesa")
        fetchRequest.predicate = NSPredicate(format: "id == %@", spesa.id as CVarArg)
        
        do {
            let speseDaEliminare = try context.fetch(fetchRequest)
            
            for sp in speseDaEliminare {
                context.delete(sp)
            }
            
            try context.save()
            
            // Rimuovi dall'array locale
            DispatchQueue.main.async {
                self.spese.removeAll { $0.id == spesa.id }
            }
            
            print("✅ Spesa eliminata")
            
        } catch {
            print("❌ Errore eliminazione spesa: \(error)")
        }
    }
    
    // MARK: - Metodi di Conversione
    
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
        
        let id = cdObject.value(forKey: "id") as? UUID ?? UUID()
        let telefono = cdObject.value(forKey: "telefono") as? String ?? ""
        let note = cdObject.value(forKey: "note") as? String ?? ""
        
        return Prenotazione(
            id: id,
            strutturaId: cdObject.value(forKey: "strutturaId") as? UUID,
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
        
        let id = cdObject.value(forKey: "id") as? UUID ?? UUID()
        return Spesa(
            id: id,
            strutturaId: cdObject.value(forKey: "strutturaId") as? UUID,
            descrizione: descrizione,
            importo: importo,
            data: data,
            categoria: Spesa.CategoriaSpesa(rawValue: categoria) ?? .altro
        )
    }
    
    private func convertToMovimentoFinanziario(from cdObject: NSManagedObject) -> MovimentoFinanziario? {
        guard let descrizione = cdObject.value(forKey: "descrizione") as? String,
              let importo = cdObject.value(forKey: "importo") as? Double,
              let data = cdObject.value(forKey: "data") as? Date,
              let tipoRaw = cdObject.value(forKey: "tipo") as? String,
              let categoriaRaw = cdObject.value(forKey: "categoria") as? String,
              let metodoPagamentoRaw = cdObject.value(forKey: "metodoPagamento") as? String else {
            return nil
        }

        let id = cdObject.value(forKey: "id") as? UUID ?? UUID()
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
            id: id,
            descrizione: descrizione,
            importo: importo,
            data: data,
            tipo: tipo,
            categoria: categoria,
            metodoPagamento: metodoPagamento,
            note: note,
            prenotazioneId: prenotazioneId,
            strutturaId: cdObject.value(forKey: "strutturaId") as? UUID,
            updatedAt: updatedAt,
            createdAt: createdAt
        )
    }
    
    // MARK: - Helper per Salvataggio Core Data
    
    private func salvaPrenotazioneInCoreData(_ prenotazione: Prenotazione, context: NSManagedObjectContext) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDPrenotazione", in: context) else {
            print("❌ Entità CDPrenotazione non trovata")
            return false
        }
        
        // Controlla se esiste già
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
        fetchRequest.predicate = NSPredicate(format: "id == %@", prenotazione.id as CVarArg)
        
        do {
            let existingPrenotazioni = try context.fetch(fetchRequest)
            let cdPrenotazione = existingPrenotazioni.first ?? NSManagedObject(entity: entity, insertInto: context)
            
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
            if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
                cdPrenotazione.setValue(activeId, forKey: "strutturaId")
            }
            cdPrenotazione.setValue(Date(), forKey: "updatedAt")
            
            // Solo per i nuovi record
            if existingPrenotazioni.isEmpty {
                cdPrenotazione.setValue(Date(), forKey: "createdAt")
            }
            
            return true
            
        } catch {
            print("❌ Errore controllo esistenza prenotazione: \(error)")
            return false
        }
    }
    
    private func salvaSpesaInCoreData(_ spesa: Spesa, context: NSManagedObjectContext) -> Bool {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDSpesa", in: context) else {
            print("❌ Entità CDSpesa non trovata")
            return false
        }
        
        // Controlla se esiste già
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDSpesa")
        fetchRequest.predicate = NSPredicate(format: "id == %@", spesa.id as CVarArg)
        
        do {
            let existingSpese = try context.fetch(fetchRequest)
            let cdSpesa = existingSpese.first ?? NSManagedObject(entity: entity, insertInto: context)
            
            cdSpesa.setValue(spesa.id, forKey: "id")
            cdSpesa.setValue(spesa.descrizione, forKey: "descrizione")
            cdSpesa.setValue(spesa.importo, forKey: "importo")
            cdSpesa.setValue(spesa.data, forKey: "data")
            cdSpesa.setValue(spesa.categoria.rawValue, forKey: "categoria")
            if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
                cdSpesa.setValue(activeId, forKey: "strutturaId")
            }
            cdSpesa.setValue(Date(), forKey: "updatedAt")
            
            // Solo per i nuovi record
            if existingSpese.isEmpty {
                cdSpesa.setValue(Date(), forKey: "createdAt")
            }
            
            return true
            
        } catch {
            print("❌ Errore controllo esistenza spesa: \(error)")
            return false
        }
    }
    
    // MARK: - Migrazione da JSON (Usa solo la prima volta se hai dati esistenti)
    
    func migraDaJSONUnaVolta() {
        print("🔄 Controllo migrazione da JSON...")
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let context = CoreDataManager.shared.viewContext
        
        // Migra prenotazioni
        let prenotazioniURL = documentsURL.appendingPathComponent("prenotazioni.json")
        if FileManager.default.fileExists(atPath: prenotazioniURL.path) {
            migraPrenotazioniDaJSON(url: prenotazioniURL, context: context)
        }
        
        // Migra spese
        let speseURL = documentsURL.appendingPathComponent("spese.json")
        if FileManager.default.fileExists(atPath: speseURL.path) {
            migraSpeseDaJSON(url: speseURL, context: context)
        }
        
        // Salva tutto
        do {
            try context.save()
            print("✅ Migrazione da JSON completata")
            
            // Ricarica i dati
            caricaDatiDaCoreData()
            
        } catch {
            print("❌ Errore durante il salvataggio della migrazione: \(error)")
        }
    }
    
    private func migraPrenotazioniDaJSON(url: URL, context: NSManagedObjectContext) {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let prenotazioniDaJSON = try decoder.decode([Prenotazione].self, from: jsonData)
            
            for prenotazione in prenotazioniDaJSON {
                _ = salvaPrenotazioneInCoreData(prenotazione, context: context)
            }
            
            // Elimina il file JSON dopo la migrazione
            try FileManager.default.removeItem(at: url)
            print("✅ Migrate \(prenotazioniDaJSON.count) prenotazioni da JSON")
            
        } catch {
            print("❌ Errore migrazione prenotazioni JSON: \(error)")
        }
    }
    
    private func migraSpeseDaJSON(url: URL, context: NSManagedObjectContext) {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let speseDaJSON = try decoder.decode([Spesa].self, from: jsonData)
            
            for spesa in speseDaJSON {
                _ = salvaSpesaInCoreData(spesa, context: context)
            }
            
            // Elimina il file JSON dopo la migrazione
            try FileManager.default.removeItem(at: url)
            print("✅ Migrate \(speseDaJSON.count) spese da JSON")
            
        } catch {
            print("❌ Errore migrazione spese JSON: \(error)")
        }
    }
}
