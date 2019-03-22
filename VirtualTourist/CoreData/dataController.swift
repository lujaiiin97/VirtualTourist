//
//  dataController.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer:NSPersistentContainer
    var backgroundContext:NSManagedObjectContext!
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func configureContexts(){
        backgroundContext = persistentContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores {
            storeDescripation , error in
            guard error == nil else {
                fatalError(error as! String)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }
    
    func autoSaveViewContext(interval:TimeInterval = 30){
        guard interval > 0 else {
            print(Error.self)
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}

