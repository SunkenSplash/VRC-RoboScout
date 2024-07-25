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
    let persistentContainer: NSPersistentCloudKitContainer = {
        // creates the NSPersistentCloudKitContainer  object
        let container = NSPersistentCloudKitContainer(name: "RoboScoutData")

        // load the saved database if it exists, creates it if it does not, and returns an error under failure conditions
        container.loadPersistentStores{ (description, error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        print("Loaded Persistent Stores")
        return container
    }()
    
    // Save Core Data Context
    func saveContext() {
        print("Saving context")
        let viewContext = persistentContainer.viewContext
        do {
            try viewContext.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func createNewNote() -> TeamMatchNote {
        print("Creating new note")
        let newNote = NSEntityDescription.insertNewObject(forEntityName: "TeamMatchNote", into: persistentContainer.viewContext) as! TeamMatchNote
        saveContext()
        return newNote
    }
    
    func fetchNotes(event: Event, team: Team? = nil, completion: @escaping (FetchNotesResult) -> Void) {
        print("Fetching notes")
        let fetchRequest: NSFetchRequest<TeamMatchNote> = TeamMatchNote.fetchRequest()
        if team == nil {
            fetchRequest.predicate = NSPredicate(format: "event_id == %d", event.id)
        } else if team!.id != 0 {
            fetchRequest.predicate = NSPredicate(format: "event_id == %d AND team_id == %d", event.id, team!.id)
        } else {
            fetchRequest.predicate = NSPredicate(format: "event_id == %d AND team_number == %@", event.id, team!.number)
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
        print("Deleting note")
        persistentContainer.viewContext.delete(note)
        if save {
            saveContext()
        }
    }
    
    func deleteEmptyNotes() {
        print("Deleting empty notes")
        let fetchRequest: NSFetchRequest<TeamMatchNote> = TeamMatchNote.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        let viewContext = persistentContainer.viewContext
        var notes = [TeamMatchNote]()
        do {
            notes = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch notes")
        }
        for note in notes {
            if (note.note ?? "").isEmpty {
                deleteNote(note: note, save: false)
            }
        }
        saveContext()
    }
    
    func deleteAllNotes() {
        print("Deleting all notes")
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
