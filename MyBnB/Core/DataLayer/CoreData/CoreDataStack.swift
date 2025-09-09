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
    private init() {}

    // Redirect to CoreDataManager to avoid divergence
    var persistentContainer: NSPersistentContainer { CoreDataManager.shared.persistentContainer }
    var viewContext: NSManagedObjectContext { CoreDataManager.shared.viewContext }

    func save() {
        CoreDataManager.shared.save()
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
