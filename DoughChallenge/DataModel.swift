//
//  DataModel.swift
//  DoughChallenge
//
//  Created by Jared Wheeler on 4/1/17.
//  Copyright © 2017 Jared Wheeler. All rights reserved.
//

import Foundation
import CoreData

class DataModel: NSObject {
    
    static let sharedInstance = DataModel()
    private override init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DoughChallenge")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Remote Update Flow
    func updateListingData() {
        //Entry point for a remote sync flow.
        //Close your eyes and picture a caching system with lots of
        //interesting eviction rules, concurrency stunts, etc.
    }
    
    
    //Stand up the local store using NASDAQ data stored in the bundle.
    func initListingData() {
        guard let listingFile = Bundle.main.path(forResource: "companylist", ofType: "csv") else {return}
        var listingFileContents: String
        do {
            listingFileContents = try String(contentsOfFile: listingFile, encoding:String.Encoding.utf8)
        } catch {return}

        let csv = CSwiftV(with: listingFileContents)
        let moc: NSManagedObjectContext = self.persistentContainer.viewContext
        for row in csv.rows {
            let entity = NSEntityDescription.entity(forEntityName: "Listing", in: moc)!
            let listing = NSManagedObject(entity: entity, insertInto: moc) as! Listing
            listing.symbol = row[0]
            listing.company_name = row[1]
        }
        saveContext()
    }
}
