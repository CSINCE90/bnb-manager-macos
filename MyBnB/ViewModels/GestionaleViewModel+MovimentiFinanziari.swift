//
//  GestionaleViewModel+MovimentiFinanziari.swift
//  MyBnB
//
//  Estensione per gestire MovimentiFinanziari SOLO in Core Data
//  Integrata con il nuovo approccio senza JSON
//

import Foundation
import SwiftUI
import CoreData

// MARK: - Extension per Movimenti Finanziari (Solo Core Data)
extension GestionaleViewModel {
    
    // MARK: - Gestione Movimenti Finanziari
    
    func aggiungiMovimentoFinanziario(_ movimento: MovimentoFinanziario) {
        salvaMovimentoFinanziario(movimento)
    }
    
    func modificaMovimentoFinanziario(_ movimento: MovimentoFinanziario) {
        salvaMovimentoFinanziario(movimento) // Stessa logica, Core Data gestisce update/insert
    }
    
    func eliminaMovimentoFinanziario(_ movimento: MovimentoFinanziario) {
        eliminaMovimentoFinanziarioDaCoreData(movimento)
    }
    
    func eliminaMovimentoFinanziario(at offsets: IndexSet) {
        for index in offsets {
            let movimento = movimentiFinanziari[index]
            eliminaMovimentoFinanziarioDaCoreData(movimento)
        }
    }
    
    // MARK: - Salvataggio Movimenti Finanziari
    
    func salvaMovimentoFinanziario(_ movimento: MovimentoFinanziario) {
        let context = CoreDataManager.shared.viewContext
        
        if salvaMovimentoFinanziarioInCoreData(movimento, context: context) {
            do {
                try context.save()
                
                // Aggiorna l'array locale
                DispatchQueue.main.async {
                    if let index = self.movimentiFinanziari.firstIndex(where: { $0.id == movimento.id }) {
                        self.movimentiFinanziari[index] = movimento
                    } else {
                        self.movimentiFinanziari.append(movimento)
                        // Ordina per data (più recenti prima)
                        self.movimentiFinanziari.sort { $0.data > $1.data }
                    }
                }
                
                print("✅ Movimento finanziario salvato in Core Data")
                
            } catch {
                print("❌ Errore salvataggio movimento finanziario: \(error)")
            }
        }
    }
    
    // MARK: - Eliminazione Movimenti Finanziari
    
    private func eliminaMovimentoFinanziarioDaCoreData(_ movimento: MovimentoFinanziario) {
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
            DispatchQueue.main.async {
                self.movimentiFinanziari.removeAll { $0.id == movimento.id }
            }
            
            print("✅ Movimento finanziario eliminato")
            
        } catch {
            print("❌ Errore eliminazione movimento finanziario: \(error)")
        }
    }
    
    // MARK: - Helper per Salvataggio Core Data
    
    private func salvaMovimentoFinanziarioInCoreData(_ movimento: MovimentoFinanziario, context: NSManagedObjectContext) -> Bool {
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
            if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
                cdMovimento.setValue(activeId, forKey: "strutturaId")
            }
            
            // Solo per i nuovi record
            if existingMovimenti.isEmpty {
                cdMovimento.setValue(movimento.createdAt, forKey: "createdAt")
            }

            // Collega relazione alla prenotazione se disponibile
            if let prenId = movimento.prenotazioneId {
                let req = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
                req.predicate = NSPredicate(format: "id == %@", prenId as CVarArg)
                if let cdPren = try context.fetch(req).first {
                    cdMovimento.setValue(cdPren, forKey: "prenotazione")
                } else {
                    cdMovimento.setValue(nil, forKey: "prenotazione")
                }
            } else {
                cdMovimento.setValue(nil, forKey: "prenotazione")
            }
            
            return true
            
        } catch {
            print("❌ Errore controllo esistenza movimento: \(error)")
            return false
        }
    }
    
    // MARK: - Calcoli e Statistiche Movimenti
    
    var entrateMovimenti: Double {
        movimentiFinanziari
            .filter { $0.tipo == .entrata }
            .reduce(0) { $0 + $1.importo }
    }
    
    var usciteMovimenti: Double {
        movimentiFinanziari
            .filter { $0.tipo == .uscita }
            .reduce(0) { $0 + $1.importo }
    }
    
    var saldoMovimenti: Double {
        entrateMovimenti - usciteMovimenti
    }
    
    func movimentiPerCategoria(_ categoria: MovimentoFinanziario.CategoriaMovimento) -> [MovimentoFinanziario] {
        movimentiFinanziari.filter { $0.categoria == categoria }
    }
    
    func movimentiPerMese(mese: Int, anno: Int) -> [MovimentoFinanziario] {
        movimentiFinanziari.filter { movimento in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.month, .year], from: movimento.data)
            return components.month == mese && components.year == anno
        }
    }
    
    // MARK: - Migrazione da JSON (Da usare solo una volta se necessario)
    
    func migraDaJSONSeNecessario() {
        // Solo se hai ancora dati JSON da migrare
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let movimentiURL = documentsURL.appendingPathComponent("movimenti.json")
        
        guard FileManager.default.fileExists(atPath: movimentiURL.path) else {
            print("📄 Nessun file JSON dei movimenti da migrare")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: movimentiURL)
            let decoder = JSONDecoder()
            let movimentiDaJSON = try decoder.decode([MovimentoFinanziario].self, from: jsonData)
            
            print("🔄 Migrazione \(movimentiDaJSON.count) movimenti da JSON a Core Data...")
            
            let context = CoreDataManager.shared.viewContext
            
            for movimento in movimentiDaJSON {
                _ = salvaMovimentoFinanziarioInCoreData(movimento, context: context)
            }
            
            try context.save()
            
            // Ricarica i dati
            caricaMovimentiFinanziariDaCoreData()
            
            // Elimina il file JSON dopo la migrazione
            try FileManager.default.removeItem(at: movimentiURL)
            
            print("✅ Migrazione movimenti completata e file JSON eliminato")
            
        } catch {
            print("❌ Errore durante la migrazione movimenti: \(error)")
        }
    }
}
