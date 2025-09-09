//
//  BilancioService.swift
//  MyBnB
//
//  Created by Francesco Chifari on 02/09/25.
//

import Foundation
import SwiftUI
import CoreData

@MainActor
class BilancioService: ObservableObject {
    @Published var movimenti: [MovimentoFinanziario] = []
    @Published var bonifici: [Bonifico] = []
    @Published var riepiloghiMensili: [RiepilogoMensile] = []
    @Published var isLoading = false
    @Published var selectedMonth = Date()
    private let context = CoreDataManager.shared.viewContext

    private let viewModel: GestionaleViewModel
    
    init(viewModel: GestionaleViewModel) {
        self.viewModel = viewModel
        Task {
            await loadData()
        }
    }
    
    // MARK: - Loading Data
    
    func loadData() async {
        isLoading = true
        // Carica da Core Data
        loadMovimentiFromCoreData()
        loadBonificiFromCoreData()
        
        // Genera automaticamente movimenti dalle prenotazioni mancanti
        await generateMovimentiFromPrenotazioni()
        // Migra eventuale legacy bonifici.json una sola volta
        migrateLegacyBonificiIfNeeded()
        
        // Calcola riepiloghi mensili
        await calculateRiepiloghiMensili()
        
        isLoading = false
    }
    
    private func generateMovimentiFromPrenotazioni() async {
        // Genera automaticamente entrate dalle prenotazioni confermate
        for prenotazione in viewModel.prenotazioni {
            guard prenotazione.statoPrenotazione == .confermata || prenotazione.statoPrenotazione == .completata else { continue }
            
            // Verifica se esiste già un movimento per questa prenotazione
            let esisteGia = movimenti.contains { $0.prenotazioneId == prenotazione.id }
            if esisteGia { continue }
            
            let movimento = MovimentoFinanziario(
                descrizione: "Prenotazione: \(prenotazione.nomeOspite)",
                importo: prenotazione.prezzoTotale,
                data: prenotazione.dataCheckIn,
                tipo: .entrata,
                categoria: .prenotazioni,
                metodoPagamento: .bookingcom,
                note: "Auto-generato da prenotazione",
                prenotazioneId: prenotazione.id
            )
            
            movimenti.append(movimento)
            // Persisti subito in Core Data
            upsertMovimentoInCoreData(movimento)
        }
        // Ricarica
        loadMovimentiFromCoreData()
    }

    // MARK: - Legacy Migration
    private func migrateLegacyBonificiIfNeeded() {
        let flagKey = "migrated_legacy_bonifici"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documents.appendingPathComponent("bonifici.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Bonifico].self, from: data)
            for b in decoded { upsertBonificoInCoreData(b) }
            try? FileManager.default.removeItem(at: url)
            UserDefaults.standard.set(true, forKey: flagKey)
            loadBonificiFromCoreData()
            print("✅ Migrazione legacy bonifici.json completata")
        } catch {
            print("⚠️ Errore migrazione legacy bonifici: \(error)")
        }
    }
    
    // MARK: - CRUD Movimenti
    
    func addMovimento(_ movimento: MovimentoFinanziario) async {
        upsertMovimentoInCoreData(movimento)
        loadMovimentiFromCoreData()
        await calculateRiepiloghiMensili()
    }
    
    func updateMovimento(_ movimento: MovimentoFinanziario) async {
        var updated = movimento
        updated.updatedAt = Date()
        upsertMovimentoInCoreData(updated)
        loadMovimentiFromCoreData()
        await calculateRiepiloghiMensili()
    }
    
    func deleteMovimento(_ movimento: MovimentoFinanziario) async {
        deleteMovimentoFromCoreData(movimento.id)
        loadMovimentiFromCoreData()
        await calculateRiepiloghiMensili()
    }
    
    // MARK: - CRUD Bonifici
    
    func addBonifico(_ bonifico: Bonifico) async {
        // Persisti bonifico
        upsertBonificoInCoreData(bonifico)
        
        // Crea automaticamente un movimento finanziario associato
        let movimento = MovimentoFinanziario(
            descrizione: "Bonifico: \(bonifico.causale)",
            importo: abs(bonifico.importoNetto),
            data: bonifico.data,
            tipo: bonifico.tipo == .ricevuto ? .entrata : .uscita,
            categoria: bonifico.tipo == .ricevuto ? .altreEntrate : .altreSpese,
            metodoPagamento: .bonifico,
            note: "CRO: \(bonifico.cro)"
        )
        
        await addMovimento(movimento)
        
        // Collega il movimento al bonifico e salva
        var updatedBonifico = bonifico
        updatedBonifico.movimentoId = movimento.id
        upsertBonificoInCoreData(updatedBonifico)
        loadBonificiFromCoreData()
    }
    
    func updateBonifico(_ bonifico: Bonifico) async {
        var updated = bonifico
        updated.updatedAt = Date()
        upsertBonificoInCoreData(updated)
        
        // Aggiorna anche il movimento associato se esiste
        if let movimentoId = bonifico.movimentoId,
           let movimentoIndex = movimenti.firstIndex(where: { $0.id == movimentoId }) {
            var movimento = movimenti[movimentoIndex]
            movimento.importo = abs(bonifico.importoNetto)
            movimento.descrizione = "Bonifico: \(bonifico.causale)"
            movimento.data = bonifico.data
            movimento.note = "CRO: \(bonifico.cro)"
            movimento.updatedAt = Date()
            upsertMovimentoInCoreData(movimento)
        }
        
        loadMovimentiFromCoreData()
        loadBonificiFromCoreData()
    }
    
    func deleteBonifico(_ bonifico: Bonifico) async {
        // Elimina anche il movimento associato
        if let movimentoId = bonifico.movimentoId {
            deleteMovimentoFromCoreData(movimentoId)
        }
        
        deleteBonificoFromCoreData(bonifico.id)
        loadMovimentiFromCoreData()
        loadBonificiFromCoreData()
        await calculateRiepiloghiMensili()
    }
    
    // MARK: - Calcoli e Analytics
    
    private func calculateRiepiloghiMensili() async {
        var riepiloghi: [RiepilogoMensile] = []
        
        let grouped = Dictionary(grouping: movimenti) { movimento in
            let components = Calendar.current.dateComponents([.year, .month], from: movimento.data)
            let year = components.year ?? 0
            let month = components.month ?? 0
            return "\(year)-\(month)"
        }
        
        for (key, movimentiMese) in grouped {
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let anno = Int(parts[0]),
                  let mese = Int(parts[1]) else { continue }
            let entrate = movimentiMese.filter { $0.tipo == .entrata }
            let uscite = movimentiMese.filter { $0.tipo == .uscita }
            
            let entratePrenotazioni = entrate.filter { $0.categoria == .prenotazioni }.reduce(0) { $0 + $1.importo }
            let altreEntrate = entrate.filter { $0.categoria != .prenotazioni }.reduce(0) { $0 + $1.importo }
            let totaleEntrate = entrate.reduce(0) { $0 + $1.importo }
            let totaleUscite = uscite.reduce(0) { $0 + $1.importo }
            
            // Bonifici del mese
            let bonificiMese = bonifici.filter { bonifico in
                let components = Calendar.current.dateComponents([.year, .month], from: bonifico.data)
                return components.year == anno && components.month == mese
            }
            
            let bonificiRicevuti = bonificiMese.filter { $0.tipo == .ricevuto }.reduce(0) { $0 + $1.importo }
            let bonificiInviati = bonificiMese.filter { $0.tipo == .inviato }.reduce(0) { $0 + $1.importo }
            
            // Conta prenotazioni del mese
            let prenotazioniMese = viewModel.prenotazioni.filter { prenotazione in
                let components = Calendar.current.dateComponents([.year, .month], from: prenotazione.dataCheckIn)
                return components.year == anno && components.month == mese
            }
            
            let riepilogo = RiepilogoMensile(
                mese: mese,
                anno: anno,
                entratePrenotazioni: entratePrenotazioni,
                altreEntrate: altreEntrate,
                totaleEntrate: totaleEntrate,
                totaleUscite: totaleUscite,
                saldoMensile: totaleEntrate - totaleUscite,
                bonificiRicevuti: bonificiRicevuti,
                bonificiInviati: bonificiInviati,
                numeroPrenotazioni: prenotazioniMese.count,
                numeroMovimenti: movimentiMese.count,
                numeroBonifici: bonificiMese.count
            )
            
            riepiloghi.append(riepilogo)
        }
        
        // Ordina per data (più recente prima)
        riepiloghiMensili = riepiloghi.sorted {
            ($0.anno, $0.mese) > ($1.anno, $1.mese)
        }
    }
    
    // MARK: - Filtri e Query
    
    func movimentiPerMese(_ mese: Int, anno: Int) -> [MovimentoFinanziario] {
        movimenti.filter { movimento in
            let components = Calendar.current.dateComponents([.year, .month], from: movimento.data)
            return components.year == anno && components.month == mese
        }.sorted { $0.data > $1.data }
    }
    
    func bonificiPerMese(_ mese: Int, anno: Int) -> [Bonifico] {
        bonifici.filter { bonifico in
            let components = Calendar.current.dateComponents([.year, .month], from: bonifico.data)
            return components.year == anno && components.month == mese
        }.sorted { $0.data > $1.data }
    }
    
    func searchMovimenti(query: String) -> [MovimentoFinanziario] {
        guard !query.isEmpty else { return movimenti }
        
        return movimenti.filter { movimento in
            movimento.descrizione.localizedCaseInsensitiveContains(query) ||
            movimento.note.localizedCaseInsensitiveContains(query) ||
            movimento.categoria.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchBonifici(query: String) -> [Bonifico] {
        guard !query.isEmpty else { return bonifici }
        
        return bonifici.filter { bonifico in
            bonifico.ordinante.localizedCaseInsensitiveContains(query) ||
            bonifico.beneficiario.localizedCaseInsensitiveContains(query) ||
            bonifico.causale.localizedCaseInsensitiveContains(query) ||
            bonifico.cro.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Persistenza Core Data
    
    private func loadMovimentiFromCoreData() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        request.fetchBatchSize = 200
        if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
            request.predicate = NSPredicate(format: "strutturaId == %@ OR strutturaId == nil", activeId as CVarArg)
        }
        do {
            let items = try context.fetch(request)
            self.movimenti = items.compactMap { (cd) -> MovimentoFinanziario? in
                guard let descrizione = cd.value(forKey: "descrizione") as? String,
                      let importo = cd.value(forKey: "importo") as? Double,
                      let data = cd.value(forKey: "data") as? Date,
                      let tipoRaw = cd.value(forKey: "tipo") as? String,
                      let categoriaRaw = cd.value(forKey: "categoria") as? String,
                      let metodoPagamentoRaw = cd.value(forKey: "metodoPagamento") as? String
                else { return nil }
                let id = cd.value(forKey: "id") as? UUID ?? UUID()
                let note = cd.value(forKey: "note") as? String ?? ""
                let prenotazioneId = cd.value(forKey: "prenotazioneId") as? UUID
                let updatedAt = cd.value(forKey: "updatedAt") as? Date ?? Date()
                let createdAt = cd.value(forKey: "createdAt") as? Date ?? Date()
                guard let tipo = MovimentoFinanziario.TipoMovimento(rawValue: tipoRaw),
                      let categoria = MovimentoFinanziario.CategoriaMovimento(rawValue: categoriaRaw),
                      let metodoPagamento = MovimentoFinanziario.MetodoPagamento(rawValue: metodoPagamentoRaw)
                else { return nil }
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
                    updatedAt: updatedAt,
                    createdAt: createdAt
                )
            }
        } catch {
            print("❌ Errore caricamento movimenti: \(error)")
        }
    }
    
    private func upsertMovimentoInCoreData(_ movimento: MovimentoFinanziario) {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDMovimentoFinanziario", in: context) else { return }
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        fetch.predicate = NSPredicate(format: "id == %@", movimento.id as CVarArg)
        do {
            let existing = try context.fetch(fetch)
            let cd = existing.first ?? NSManagedObject(entity: entity, insertInto: context)
            cd.setValue(movimento.id, forKey: "id")
            cd.setValue(movimento.descrizione, forKey: "descrizione")
            cd.setValue(movimento.importo, forKey: "importo")
            cd.setValue(movimento.data, forKey: "data")
            cd.setValue(movimento.tipo.rawValue, forKey: "tipo")
            cd.setValue(movimento.categoria.rawValue, forKey: "categoria")
            cd.setValue(movimento.metodoPagamento.rawValue, forKey: "metodoPagamento")
            cd.setValue(movimento.note, forKey: "note")
            cd.setValue(movimento.prenotazioneId, forKey: "prenotazioneId")
            cd.setValue(Date(), forKey: "updatedAt")
            if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "") {
                cd.setValue(activeId, forKey: "strutturaId")
            }
            if existing.isEmpty { cd.setValue(movimento.createdAt, forKey: "createdAt") }

            // Collega relazione alla prenotazione se disponibile
            if let prenId = movimento.prenotazioneId {
                let req = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
                req.predicate = NSPredicate(format: "id == %@", prenId as CVarArg)
                if let cdPren = try context.fetch(req).first {
                    cd.setValue(cdPren, forKey: "prenotazione")
                } else {
                    cd.setValue(nil, forKey: "prenotazione")
                }
            } else {
                cd.setValue(nil, forKey: "prenotazione")
            }
            try context.save()
        } catch {
            print("❌ Errore salvataggio movimento: \(error)")
        }
    }
    
    private func deleteMovimentoFromCoreData(_ id: UUID) {
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let existing = try context.fetch(fetch)
            for item in existing { context.delete(item) }
            try context.save()
        } catch {
            print("❌ Errore eliminazione movimento: \(error)")
        }
    }
    
    private func loadBonificiFromCoreData() {
        guard NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["CDBonifico"] != nil else { return }
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDBonifico")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        request.fetchBatchSize = 200
        do {
            let items = try context.fetch(request)
            self.bonifici = items.compactMap { (cd) -> Bonifico? in
                let id = cd.value(forKey: "id") as? UUID ?? UUID()
                guard let importo = cd.value(forKey: "importo") as? Double,
                      let data = cd.value(forKey: "data") as? Date,
                      let tipoRaw = cd.value(forKey: "tipo") as? String,
                      let statoRaw = cd.value(forKey: "stato") as? String
                else { return nil }
                let dataValuta = cd.value(forKey: "dataValuta") as? Date
                let ordinante = cd.value(forKey: "ordinante") as? String ?? ""
                let beneficiario = cd.value(forKey: "beneficiario") as? String ?? ""
                let causale = cd.value(forKey: "causale") as? String ?? ""
                let cro = cd.value(forKey: "cro") as? String ?? ""
                let iban = cd.value(forKey: "iban") as? String ?? ""
                let banca = cd.value(forKey: "banca") as? String ?? ""
                let commissioni = cd.value(forKey: "commissioni") as? Double ?? 0
                let note = cd.value(forKey: "note") as? String ?? ""
                let movimentoId = cd.value(forKey: "movimentoId") as? UUID
                guard let tipo = Bonifico.TipoBonifico(rawValue: tipoRaw),
                      let stato = Bonifico.StatoBonifico(rawValue: statoRaw) else { return nil }
                let bonifico = Bonifico(
                    id: id,
                    importo: importo,
                    data: data,
                    dataValuta: dataValuta,
                    ordinante: ordinante,
                    beneficiario: beneficiario,
                    causale: causale,
                    cro: cro,
                    iban: iban,
                    banca: banca,
                    tipo: tipo,
                    stato: stato,
                    commissioni: commissioni,
                    note: note,
                    movimentoId: movimentoId
                )
                return bonifico
            }
        } catch {
            print("❌ Errore caricamento bonifici: \(error)")
        }
    }
    
    private func upsertBonificoInCoreData(_ bonifico: Bonifico) {
        guard NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["CDBonifico"] != nil else { return }
        guard let entity = NSEntityDescription.entity(forEntityName: "CDBonifico", in: context) else { return }
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDBonifico")
        fetch.predicate = NSPredicate(format: "id == %@", bonifico.id as CVarArg)
        do {
            let existing = try context.fetch(fetch)
            let cd = existing.first ?? NSManagedObject(entity: entity, insertInto: context)
            cd.setValue(bonifico.id, forKey: "id")
            cd.setValue(bonifico.importo, forKey: "importo")
            cd.setValue(bonifico.data, forKey: "data")
            cd.setValue(bonifico.dataValuta, forKey: "dataValuta")
            cd.setValue(bonifico.ordinante, forKey: "ordinante")
            cd.setValue(bonifico.beneficiario, forKey: "beneficiario")
            cd.setValue(bonifico.causale, forKey: "causale")
            cd.setValue(bonifico.cro, forKey: "cro")
            cd.setValue(bonifico.iban, forKey: "iban")
            cd.setValue(bonifico.banca, forKey: "banca")
            cd.setValue(bonifico.tipo.rawValue, forKey: "tipo")
            cd.setValue(bonifico.stato.rawValue, forKey: "stato")
            cd.setValue(bonifico.commissioni, forKey: "commissioni")
            cd.setValue(bonifico.note, forKey: "note")
            cd.setValue(bonifico.movimentoId, forKey: "movimentoId")
            cd.setValue(Date(), forKey: "updatedAt")
            if existing.isEmpty { cd.setValue(bonifico.createdAt, forKey: "createdAt") }
            try context.save()
        } catch {
            print("❌ Errore salvataggio bonifico: \(error)")
        }
    }
    
    private func deleteBonificoFromCoreData(_ id: UUID) {
        guard NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["CDBonifico"] != nil else { return }
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDBonifico")
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let existing = try context.fetch(fetch)
            for item in existing { context.delete(item) }
            try context.save()
        } catch {
            print("❌ Errore eliminazione bonifico: \(error)")
        }
    }
    
    // MARK: - Export & Import
    
    func exportBilancio(periodo: DateInterval) -> Data? {
        let movimentiPeriodo = movimenti.filter { movimento in
            periodo.contains(movimento.data)
        }
        
        let bonificiPeriodo = bonifici.filter { bonifico in
            periodo.contains(bonifico.data)
        }
        
        let export = [
            "periodo": [
                "inizio": periodo.start,
                "fine": periodo.end
            ],
            "movimenti": movimentiPeriodo,
            "bonifici": bonificiPeriodo,
            "riepilogo": riepiloghiMensili.filter { riepilogo in
                let date = Calendar.current.date(from: DateComponents(year: riepilogo.anno, month: riepilogo.mese)) ?? Date()
                return periodo.contains(date)
            }
        ] as [String: Any]
        
        return try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
    }
}
