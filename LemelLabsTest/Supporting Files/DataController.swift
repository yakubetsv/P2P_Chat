//
//  DataController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 1.04.21.
//

import Foundation
import CoreData

class DataController: NSObject {
    
    var managedObjectContext: NSManagedObjectContext
    
    init(completion: @escaping () -> ()) {
        guard let modelURL = Bundle.main.url(forResource: "LemelLabsTest", withExtension:"momd") else {
                fatalError("Error loading model from bundle")
            }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Error initializing mom from: \(modelURL)")
            }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
            queue.async {
                guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                    fatalError("Unable to resolve document directory")
                }
                let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
                do {
                    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                    DispatchQueue.main.sync(execute: completion)
                } catch {
                    fatalError("Error migrating store: \(error)")
                }
            }
    }
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
