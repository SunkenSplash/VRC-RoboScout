//
//  RoboScoutDataController.swift
//  VRC RoboScout
//
//  Created by William Castro on 9/14/23.
//

import CoreData

enum FetchNotesResult {
    case success([TeamMatchNote])
    case failure(Error)
}

class RoboScoutDataController: ObservableObject {
    
    // Create NSPersistentCloudKitContainer 
    let persistentContainer: NSPersistentCloudKitContainer  = {
        // creates the NSPersistentCloudKitContainer  object
        let container = NSPersistentCloudKitContainer (name: "RoboScoutData")

        // load the saved database if it exists, creates it if it does not, and returns an error under failure conditions
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        print("Loaded Persistent Stores")
        return container
    }()
    
    // Save Core Data Context
    func saveContext() {
        let viewContext = persistentContainer.viewContext
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func createNewNote() -> TeamMatchNote {
        let newNote = NSEntityDescription.insertNewObject(forEntityName: "TeamMatchNote", into: persistentContainer.viewContext) as! TeamMatchNote
        return newNote
    }
    
    func fetchNotes(event: Event, team: Team, completion: @escaping (FetchNotesResult) -> Void) {
        let fetchRequest: NSFetchRequest<TeamMatchNote> = TeamMatchNote.fetchRequest()
        
        if team.id != 0 {
            fetchRequest.predicate = NSPredicate(format: "event_id == %d AND team_id == %d", event.id, team.id)
        } else {
            fetchRequest.predicate = NSPredicate(format: "event_id == %d AND team_number == %@", event.id, team.number)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        let viewContext = persistentContainer.viewContext

        do {
            let notes = try viewContext.fetch(fetchRequest)
            completion(.success(notes))
        } catch {
            print("Failed to fetch notes")
            completion(.failure(error))
        }
    }
    
    func deleteNote(note: TeamMatchNote, save: Bool = true) {
        // Delete the user-selected item from the context
        let viewContext = persistentContainer.viewContext
        viewContext.delete(note)
        
        if save {
            // Save changes to the Managed Object Context
            saveContext()
        }
    }
    
    func deleteAllNotes() {
        let viewContext = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TeamMatchNote")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try viewContext.execute(deleteRequest)
            print("Batch deleted notes")
        } catch let error as NSError {
            print("Failed to batch delete notes (\(error))")
        }
    }
}
