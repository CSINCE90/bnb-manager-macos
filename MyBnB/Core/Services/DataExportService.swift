import Foundation
import CoreData

@MainActor
final class DataExportService {
    static let shared = DataExportService()
    private init() {}

    private var context: NSManagedObjectContext { CoreDataManager.shared.viewContext }

    func exportAllToJSON() -> Data? {
        var export: [String: Any] = [:]
        export["prenotazioni"] = fetchPrenotazioni()
        export["spese"] = fetchSpese()
        export["movimenti"] = fetchMovimenti()
        export["bonifici"] = fetchBonifici()
        export["exportDate"] = ISO8601DateFormatter().string(from: Date())
        export["version"] = "2.0"
        return try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
    }

    // MARK: - Fetch helpers
    private func fetchPrenotazioni() -> [[String: Any]] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDPrenotazione")
        req.sortDescriptors = [NSSortDescriptor(key: "dataCheckIn", ascending: true)]
        req.fetchBatchSize = 100
        do {
            let iso = ISO8601DateFormatter()
            let results = try context.fetch(req)
            var arr: [[String: Any]] = []
            arr.reserveCapacity(results.count)
            for cd in results {
                var row: [String: Any] = [:]
                row["id"] = (cd.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
                row["nomeOspite"] = cd.value(forKey: "nomeOspite") as? String ?? ""
                row["email"] = cd.value(forKey: "email") as? String ?? ""
                row["telefono"] = cd.value(forKey: "telefono") as? String ?? ""
                if let d = cd.value(forKey: "dataCheckIn") as? Date { row["dataCheckIn"] = iso.string(from: d) } else { row["dataCheckIn"] = "" }
                if let d = cd.value(forKey: "dataCheckOut") as? Date { row["dataCheckOut"] = iso.string(from: d) } else { row["dataCheckOut"] = "" }
                row["numeroOspiti"] = Int(cd.value(forKey: "numeroOspiti") as? Int16 ?? 0)
                row["prezzoTotale"] = cd.value(forKey: "prezzoTotale") as? Double ?? 0
                row["stato"] = cd.value(forKey: "statoPrenotazione") as? String ?? ""
                row["note"] = cd.value(forKey: "note") as? String ?? ""
                arr.append(row)
            }
            return arr
        } catch {
            print("❌ Export prenotazioni failed: \(error)")
            return []
        }
    }

    private func fetchSpese() -> [[String: Any]] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDSpesa")
        req.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        req.fetchBatchSize = 100
        do {
            let iso = ISO8601DateFormatter()
            let results = try context.fetch(req)
            var arr: [[String: Any]] = []
            arr.reserveCapacity(results.count)
            for cd in results {
                var row: [String: Any] = [:]
                row["id"] = (cd.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
                row["descrizione"] = cd.value(forKey: "descrizione") as? String ?? ""
                row["importo"] = cd.value(forKey: "importo") as? Double ?? 0
                if let d = cd.value(forKey: "data") as? Date { row["data"] = iso.string(from: d) } else { row["data"] = "" }
                row["categoria"] = cd.value(forKey: "categoria") as? String ?? "Altro"
                arr.append(row)
            }
            return arr
        } catch {
            print("❌ Export spese failed: \(error)")
            return []
        }
    }

    private func fetchMovimenti() -> [[String: Any]] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        req.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        req.fetchBatchSize = 200
        do {
            let iso = ISO8601DateFormatter()
            let results = try context.fetch(req)
            var arr: [[String: Any]] = []
            arr.reserveCapacity(results.count)
            for cd in results {
                var row: [String: Any] = [:]
                row["id"] = (cd.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
                row["descrizione"] = cd.value(forKey: "descrizione") as? String ?? ""
                row["importo"] = cd.value(forKey: "importo") as? Double ?? 0
                if let d = cd.value(forKey: "data") as? Date { row["data"] = iso.string(from: d) } else { row["data"] = "" }
                row["tipo"] = cd.value(forKey: "tipo") as? String ?? ""
                row["categoria"] = cd.value(forKey: "categoria") as? String ?? ""
                row["metodoPagamento"] = cd.value(forKey: "metodoPagamento") as? String ?? ""
                row["note"] = cd.value(forKey: "note") as? String ?? ""
                if let pid = cd.value(forKey: "prenotazioneId") as? UUID { row["prenotazioneId"] = pid.uuidString } else { row["prenotazioneId"] = NSNull() }
                if let d = cd.value(forKey: "createdAt") as? Date { row["createdAt"] = iso.string(from: d) } else { row["createdAt"] = "" }
                if let d = cd.value(forKey: "updatedAt") as? Date { row["updatedAt"] = iso.string(from: d) } else { row["updatedAt"] = "" }
                arr.append(row)
            }
            return arr
        } catch {
            print("❌ Export movimenti failed: \(error)")
            return []
        }
    }

    private func fetchBonifici() -> [[String: Any]] {
        guard NSManagedObjectModel.mergedModel(from: nil)?.entitiesByName["CDBonifico"] != nil else { return [] }
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDBonifico")
        req.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        req.fetchBatchSize = 200
        do {
            let iso = ISO8601DateFormatter()
            let results = try context.fetch(req)
            var arr: [[String: Any]] = []
            arr.reserveCapacity(results.count)
            for cd in results {
                var row: [String: Any] = [:]
                row["id"] = (cd.value(forKey: "id") as? UUID)?.uuidString ?? UUID().uuidString
                row["importo"] = cd.value(forKey: "importo") as? Double ?? 0
                if let d = cd.value(forKey: "data") as? Date { row["data"] = iso.string(from: d) } else { row["data"] = "" }
                if let d = cd.value(forKey: "dataValuta") as? Date { row["dataValuta"] = iso.string(from: d) } else { row["dataValuta"] = NSNull() }
                row["ordinante"] = cd.value(forKey: "ordinante") as? String ?? ""
                row["beneficiario"] = cd.value(forKey: "beneficiario") as? String ?? ""
                row["causale"] = cd.value(forKey: "causale") as? String ?? ""
                row["cro"] = cd.value(forKey: "cro") as? String ?? ""
                row["iban"] = cd.value(forKey: "iban") as? String ?? ""
                row["banca"] = cd.value(forKey: "banca") as? String ?? ""
                row["tipo"] = cd.value(forKey: "tipo") as? String ?? ""
                row["stato"] = cd.value(forKey: "stato") as? String ?? ""
                row["commissioni"] = cd.value(forKey: "commissioni") as? Double ?? 0
                row["note"] = cd.value(forKey: "note") as? String ?? ""
                if let mid = cd.value(forKey: "movimentoId") as? UUID { row["movimentoId"] = mid.uuidString } else { row["movimentoId"] = NSNull() }
                arr.append(row)
            }
            return arr
        } catch {
            print("❌ Export bonifici failed: \(error)")
            return []
        }
    }
}
