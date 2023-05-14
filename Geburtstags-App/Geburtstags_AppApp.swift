//
//  Geburtstags_AppApp.swift
//  Geburtstags-App
//
//  Created by Jannes Schäfer on 02.10.22.
//

import Contacts
import CoreData
import SwiftUI

let udShowWelcomeScreenKey = "showWelcomeScreen"
let udShowWelcomeScreenDefault = true
let udImportProfilesFromContactsKey = "importProfilesFromContacts"
let udImportProfilesFromContactsDefault = false
let udBirthdayNotificationsActiveKey = "birthdayNotifications"
let udBirthdayNotificationsActiveDefault = false

let unNotificationOptions: UNAuthorizationOptions = [.alert, .badge]
    
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
    @Published var profiles = [Profile]()
    
    let managedObjectContext: NSManagedObjectContext
    let tempManagedObjectContext: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.tempManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.tempManagedObjectContext.parent = managedObjectContext
        collectProfiles()
    }
    
    func collectProfiles() {
        print("Collecting profiles.")
        profiles = []
        
        // Stored profiles
        do {
            let storedProfiles = try managedObjectContext.fetch(Profile.fetchRequest())
            profiles.append(contentsOf: storedProfiles)
        } catch {
            print("Error retrieving stored profiles: \(error).")
        }
        
        // Contact profiles
        if UserDefaults.standard.bool(forKey: udImportProfilesFromContactsKey) == true,
           [.authorized, .restricted].contains(CNContactStore.authorizationStatus(for: .contacts)) {
            let store = CNContactStore()
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
            do {
                let contacts = try store.unifiedContacts(matching: NSPredicate(value: true), keysToFetch: keysToFetch)
                for contact in contacts {
                    guard let birthdayDateComponents = contact.birthday,
                          let birthday = Calendar.current.date(from: birthdayDateComponents)
                    else { continue }
                    
                    let newProfile = Profile(context: tempManagedObjectContext,
                                             identifier: contact.identifier,
                                             name: "\(contact.givenName) \(contact.familyName)",
                                             birthday: birthday,
                                             image: nil,
                                             imageData: contact.thumbnailImageData,
                                             type: .contactProfile)
                    profiles.append(newProfile)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        profiles.sort { $1.nextBirthday >= $0.nextBirthday } // Evaluate if input profiles are in increasing order.
        Task { await scheduleNotifications() }
    }
    
    func scheduleNotifications() async {
        print("Scheduling notifications.")
        if UserDefaults.standard.bool(forKey: udBirthdayNotificationsActiveKey) == true {
            let pendingNotifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
            
            // Remove notifications for users not present in the list anymore.
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:
                pendingNotifications.compactMap { pendingNotification in
                    if !(profiles.contains { $0.identifier == pendingNotification.identifier }) {
                        print("Removing notifications for identifier \(pendingNotification.identifier)")
                        return pendingNotification.identifier
                    } else {
                        return nil
                    }
                }
            )
                                                                                 
            for profile in profiles {
                guard pendingNotifications.contains(where: { profile.identifier == $0.identifier }) == false
                else { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "Another Trip Around the Sun!"
                content.body = "It's a birthday party! Join us in celebrating \(profile.name)'s birthday today and make their day unforgettable."
                let birthdayDateComponents = Calendar.current.dateComponents([.month, .day, .hour], from: profile.nextBirthday)
                let trigger = UNCalendarNotificationTrigger(dateMatching: birthdayDateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: profile.identifier, content: content, trigger: trigger)
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    print("Added scheduled notification for profile \(profile.name).")
                } catch {
                    print("Error adding scheduled notification to UNUserNotificationCenter: \(error)")
                }
            }
        } else {
            print("Removed all pending notifications.")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}

@main
struct Geburtstags_AppApp: App {
    @AppStorage(udShowWelcomeScreenKey) var showWelcomeScreen = udShowWelcomeScreenDefault
    
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
