import Foundation
import CoreData
import SwiftUI

@MainActor
final class StrutturaRepository: ObservableObject {
    @Published var strutture: [CDStruttura] = []
    private let context = CoreDataManager.shared.viewContext

    private let activeIdKey = "activeStrutturaId"
    private let activeNameKey = "activeStrutturaName"
    private let activeBookingPropertyIdKey = "activeBookingPropertyId"
    private let activeBookingUrlKey = "activeBookingUrl"

    func load() {
        let req = NSFetchRequest<CDStruttura>(entityName: "CDStruttura")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let list = try? context.fetch(req) { self.strutture = list }
    }

    func add(nome: String, indirizzo: String, citta: String, camere: Int, bookingId: String?, bookingUrl: String?, note: String? = nil, imagePath: String? = nil) {
        let cd = CDStruttura(context: context)
        cd.id = UUID()
        cd.nome = nome
        cd.indirizzo = indirizzo
        cd.citta = citta
        cd.camereTotali = Int16(camere)
        cd.bookingPropertyId = bookingId
        cd.bookingUrl = bookingUrl
        cd.setValue(note, forKey: "note")
        cd.setValue(imagePath, forKey: "imagePath")
        cd.createdAt = Date(); cd.updatedAt = Date()
        try? context.save()
        load()
    }

    func setActive(_ struttura: CDStruttura) {
        let defaults = UserDefaults.standard
        defaults.set((struttura.id ?? UUID()).uuidString, forKey: activeIdKey)
        defaults.set(struttura.nome ?? "", forKey: activeNameKey)
        defaults.set(struttura.bookingPropertyId ?? "", forKey: activeBookingPropertyIdKey)
        defaults.set(struttura.bookingUrl ?? "", forKey: activeBookingUrlKey)
        NotificationCenter.default.post(name: Notification.Name("ActiveStrutturaChanged"), object: nil)
    }

    func update(_ s: CDStruttura, nome: String, indirizzo: String, citta: String, camere: Int, bookingId: String?, bookingUrl: String?, note: String?, imagePath: String?) {
        s.nome = nome
        s.indirizzo = indirizzo
        s.citta = citta
        s.camereTotali = Int16(camere)
        s.bookingPropertyId = bookingId
        s.bookingUrl = bookingUrl
        s.setValue(note, forKey: "note")
        s.setValue(imagePath, forKey: "imagePath")
        s.updatedAt = Date()
        try? context.save()
        load()
        // Aggiorna attivazione se stai modificando quella attiva
        if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: activeIdKey) ?? ""), activeId == s.id {
            setActive(s)
        }
    }

    func delete(_ s: CDStruttura) {
        context.delete(s)
        try? context.save()
        load()
        // Se era attiva, azzera i riferimenti
        if let activeId = UUID(uuidString: UserDefaults.standard.string(forKey: activeIdKey) ?? ""), activeId == s.id {
            let d = UserDefaults.standard
            d.removeObject(forKey: activeIdKey)
            d.removeObject(forKey: activeNameKey)
            d.removeObject(forKey: activeBookingPropertyIdKey)
            d.removeObject(forKey: activeBookingUrlKey)
            NotificationCenter.default.post(name: Notification.Name("ActiveStrutturaChanged"), object: nil)
        }
    }

    // MARK: - Helpers
    func activeStructure() -> CDStruttura? {
        guard let id = UUID(uuidString: UserDefaults.standard.string(forKey: activeIdKey) ?? "") else { return nil }
        let req = NSFetchRequest<CDStruttura>(entityName: "CDStruttura")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(req).first
    }

    // MARK: - Foto Gestione
    func photos(for struttura: CDStruttura) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDFotoStruttura")
        req.predicate = NSPredicate(format: "struttura == %@", struttura)
        req.sortDescriptors = [NSSortDescriptor(key: "ordine", ascending: true), NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }

    func addPhotos(_ paths: [String], to struttura: CDStruttura) {
        guard let entity = NSEntityDescription.entity(forEntityName: "CDFotoStruttura", in: context) else { return }
        let start = (photos(for: struttura).last?.value(forKey: "ordine") as? Int ?? 0) + 1
        var idx = start
        for p in paths {
            let photo = NSManagedObject(entity: entity, insertInto: context)
            photo.setValue(UUID(), forKey: "id")
            photo.setValue(p, forKey: "path")
            photo.setValue(Int16(idx), forKey: "ordine")
            photo.setValue(Date(), forKey: "createdAt")
            photo.setValue(struttura, forKey: "struttura")
            idx += 1
        }
        try? context.save()
        load()
    }

    func deletePhoto(_ photo: NSManagedObject) {
        context.delete(photo)
        try? context.save()
    }
}
