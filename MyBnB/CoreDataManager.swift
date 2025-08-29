//
//  CoreDataManager.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // Container per Core Data
    lazy var persistentContainer: NSPersistentContainer = {
        // IMPORTANTE: Prima devi creare il file MyBnBModel.xcdatamodeld in Xcode
        let container = NSPersistentContainer(name: "MyBnBModel")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                // Per ora stampiamo solo l'errore, il vecchio sistema JSON continuerà a funzionare
                print("Core Data non disponibile: \(error)")
            } else {
                print("✅ Core Data pronto!")
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // Funzione helper per salvare
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
            print("✅ Salvato in Core Data")
        } catch {
            print("❌ Errore salvataggio: \(error)")
        }
    }
}
