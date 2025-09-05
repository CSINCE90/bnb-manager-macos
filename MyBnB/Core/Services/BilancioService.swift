//
//  BilancioService.swift
//  MyBnB
//
//  Created by Francesco Chifari on 02/09/25.
//

import Foundation
import SwiftUI

@MainActor
class BilancioService: ObservableObject {
    @Published var movimenti: [MovimentoFinanziario] = []
    @Published var bonifici: [Bonifico] = []
    @Published var riepiloghiMensili: [RiepilogoMensile] = []
    @Published var isLoading = false
    @Published var selectedMonth = Date()
    
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
        
        // Genera automaticamente movimenti dalle prenotazioni
        await generateMovimentiFromPrenotazioni()
        
        // Carica dati salvati
        loadMovimenti()
        loadBonifici()
        
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
        }
        
        saveMovimenti()
    }
    
    // MARK: - CRUD Movimenti
    
    func addMovimento(_ movimento: MovimentoFinanziario) async {
        movimenti.append(movimento)
        saveMovimenti()
        await calculateRiepiloghiMensili()
    }
    
    func updateMovimento(_ movimento: MovimentoFinanziario) async {
        if let index = movimenti.firstIndex(where: { $0.id == movimento.id }) {
            var updated = movimento
            updated.updatedAt = Date()
            movimenti[index] = updated
            saveMovimenti()
            await calculateRiepiloghiMensili()
        }
    }
    
    func deleteMovimento(_ movimento: MovimentoFinanziario) async {
        movimenti.removeAll { $0.id == movimento.id }
        saveMovimenti()
        await calculateRiepiloghiMensili()
    }
    
    // MARK: - CRUD Bonifici
    
    func addBonifico(_ bonifico: Bonifico) async {
        bonifici.append(bonifico)
        
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
        
        // Collega il movimento al bonifico
        var updatedBonifico = bonifico
        updatedBonifico.movimentoId = movimento.id
        
        if let index = bonifici.firstIndex(where: { $0.id == bonifico.id }) {
            bonifici[index] = updatedBonifico
        }
        
        saveBonifici()
    }
    
    func updateBonifico(_ bonifico: Bonifico) async {
        if let index = bonifici.firstIndex(where: { $0.id == bonifico.id }) {
            var updated = bonifico
            updated.updatedAt = Date()
            bonifici[index] = updated
            saveBonifici()
            
            // Aggiorna anche il movimento associato se esiste
            if let movimentoId = bonifico.movimentoId,
               let movimentoIndex = movimenti.firstIndex(where: { $0.id == movimentoId }) {
                var movimento = movimenti[movimentoIndex]
                movimento.importo = abs(bonifico.importoNetto)
                movimento.descrizione = "Bonifico: \(bonifico.causale)"
                movimento.data = bonifico.data
                movimento.note = "CRO: \(bonifico.cro)"
                movimento.updatedAt = Date()
                movimenti[movimentoIndex] = movimento
                saveMovimenti()
            }
        }
    }
    
    func deleteBonifico(_ bonifico: Bonifico) async {
        // Elimina anche il movimento associato
        if let movimentoId = bonifico.movimentoId {
            movimenti.removeAll { $0.id == movimentoId }
            saveMovimenti()
        }
        
        bonifici.removeAll { $0.id == bonifico.id }
        saveBonifici()
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
    
    // MARK: - Persistenza
    
    private func saveMovimenti() {
        if let encoded = try? JSONEncoder().encode(movimenti) {
            let url = getDocumentsDirectory().appendingPathComponent("movimenti.json")
            try? encoded.write(to: url)
        }
    }
    
    private func loadMovimenti() {
        let url = getDocumentsDirectory().appendingPathComponent("movimenti.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([MovimentoFinanziario].self, from: data) {
            movimenti = decoded
        }
    }
    
    private func saveBonifici() {
        if let encoded = try? JSONEncoder().encode(bonifici) {
            let url = getDocumentsDirectory().appendingPathComponent("bonifici.json")
            try? encoded.write(to: url)
        }
    }
    
    private func loadBonifici() {
        let url = getDocumentsDirectory().appendingPathComponent("bonifici.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Bonifico].self, from: data) {
            bonifici = decoded
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
