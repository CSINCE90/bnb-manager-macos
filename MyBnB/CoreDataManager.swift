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
        let container = NSPersistentContainer(name: "MyBnBModel")
        
        // Abilita migrazione leggera automatica
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data non disponibile: \(error)")
            } else {
                print("✅ Core Data pronto!")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
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
