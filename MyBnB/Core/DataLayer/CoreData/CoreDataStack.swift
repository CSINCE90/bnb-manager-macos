//
//  CoreDataStack.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//

import CoreData
import Foundation

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    private let modelName = "MyBnBModel"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber,
                              forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber,
                              forKey: NSInferMappingModelAutomaticallyOption)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data failed to load: \(error)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
