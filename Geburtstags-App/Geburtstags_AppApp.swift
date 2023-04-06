//
//  Geburtstags_AppApp.swift
//  Geburtstags-App
//
//  Created by Jannes Schäfer on 02.10.22.
//

import Contacts
import CoreData
import SwiftUI

class CoreDataManager {
    var container: NSPersistentContainer
    var loadError: NSError?
    
    init() {
        container = NSPersistentContainer(name: "Geburtstags-App")
        container.loadPersistentStores { _, error in
            if let error = error as? NSError {
                self.loadError = error
                print("CoreData container load persistent stores failed: \(error).")
            }
            print("CoreData stores loaded.")
        }
        whereIsMySQLite()
    }
    
    func whereIsMySQLite() {
        let path = FileManager
            .default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .last?
            .absoluteString
            .replacingOccurrences(of: "file://", with: "")
            .removingPercentEncoding
        
        if let path = path {
            print("SQLite file in: \(path)")
        } else {
            print("SQLite directory not found.")
        }
    }
}

class ProfileManager: ObservableObject {
    @Published var storedProfiles = [StoredProfile]()
    @Published var contactProfiles = [ContactProfile]()
    
    let managedObjectContext: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        collectProfiles()
    }
    
    func collectProfiles() {
        print("Collecting profiles.")
        storedProfiles = []
        contactProfiles = []
        do {
            storedProfiles = try managedObjectContext.fetch(StoredProfile.fetchRequest())
        } catch {
            print("Error retrieving stored profiles: \(error).")
        }
        
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey, CNContactImageDataKey] as [CNKeyDescriptor]
        do {
            let contacts = try store.unifiedContacts(matching: NSPredicate(value: true), keysToFetch: keysToFetch)
            for contact in contacts {
                guard let birthdayDateComponents = contact.birthday,
                      let birthday = Calendar.current.date(from: birthdayDateComponents)
                else { continue }
                
                let newProfile = ContactProfile(
                    contactIdentifier: contact.identifier,
                    name: "\(contact.givenName) \(contact.familyName)",
                    birthday: birthday,
                    image: contact.imageData
                )
                contactProfiles.append(newProfile)
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

@main
struct Geburtstags_AppApp: App {
    // Will only have true as a value if showWelcomeScreen wasn't yet changed at any point in time.
    @AppStorage("showWelcomeScreen") var showWelcomeScreen = true
    
    let coreDataManager: CoreDataManager
    let profileManager: ProfileManager
    
    init() {
        coreDataManager = CoreDataManager()
        profileManager = ProfileManager(managedObjectContext: coreDataManager.container.viewContext)
    }
    
    var body: some Scene {
        WindowGroup {
            if coreDataManager.loadError != nil {
                Color.clear
                    .alert("Database Error", isPresented: .constant(true)) {
                        Button("Ok", role: .cancel) { exit(1) }
                    } message: {
                        Text("Issue loading this apps database. To fix, please reinstall the app.")
                            .foregroundColor(.red)
                    }
            } else {
                NavigationStack {
                    if showWelcomeScreen {
                        WelcomeScreen()
                    } else {
                        ContentView()
                    }
                }
                .environment(\.managedObjectContext, coreDataManager.container.viewContext)
                .environmentObject(profileManager)
            }
        }
    }
}
