//
//  SettingsView.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 30.03.23.
//

import Contacts
import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var profileManager: ProfileManager
    
    @AppStorage(udImportProfilesFromContactsKey) var importProfilesFromContacts = udImportProfilesFromContactsDefault
    @State var contactAuthorizationStatus: CNAuthorizationStatus = .notDetermined
    
    @AppStorage(udBirthdayNotificationsActiveKey) var birthdayNotificationsActive = udBirthdayNotificationsActiveDefault
    @State var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    if notificationAuthorizationStatus == .denied {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Please click here to grant notification access in the Settings App.")
                        }
                    }
                    
                    Toggle(isOn: .init(get: { return birthdayNotificationsActive }, set: { newValue in Task { await birthdayNotificationsToggled(newValue) } })) {
                        Text("Notifications")
                    }
                    .opacity(notificationAuthorizationStatus == .denied ? 0.4 : 1)
                }
            } footer: {
                Text("You will be notified at midnight on the day of each birthday.")
                    .opacity(notificationAuthorizationStatus == .denied ? 0.4 : 1)
            }
    
            Section {
                VStack(alignment: .leading) {
                    if contactAuthorizationStatus == .denied {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Please click here to grant contact access in the Settings App.")
                        }
                    }
                        
                    Toggle(isOn: .init(get: { return importProfilesFromContacts }, set: { newValue in Task { await importProfileFromContactsToggled(newValue) } })) {
                        Text("Import profiles from Contacts App")
                    }
                    .opacity(contactAuthorizationStatus == .denied ? 0.4 : 1)
                }
            } footer: {
                Text("Only profiles with a set birthday will be shown.")
                    .opacity(contactAuthorizationStatus == .denied ? 0.4 : 1)
            }
        }
        .navigationTitle("Settings")
        .onAppear { getCNAuthorizationStatus(); Task { await getUNAuthorizationStatus() } }
        .onChange(of: scenePhase) { if $0 == .active { getCNAuthorizationStatus(); Task { await getUNAuthorizationStatus() } } }
    }
    
    func getCNAuthorizationStatus() {
        contactAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if contactAuthorizationStatus == .denied {
            importProfilesFromContacts = false
        }
    }
    
    func getUNAuthorizationStatus() async {
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthorizationStatus = notificationSettings.authorizationStatus
        if notificationAuthorizationStatus == .denied {
            birthdayNotificationsActive = false
        }
    }
    
    func importProfileFromContactsToggled(_ newValue: Bool) async {
        if newValue == true {
            let store = CNContactStore()
            do {
                importProfilesFromContacts = try await store.requestAccess(for: .contacts)
            } catch {
                print("Error getting contact access: \(error).")
                importProfilesFromContacts = false
            }
        } else {
            importProfilesFromContacts = false
        }
        profileManager.collectProfiles()
    }
    
    func birthdayNotificationsToggled(_ newValue: Bool) async {
        if newValue == true {
            do {
                birthdayNotificationsActive = try await UNUserNotificationCenter.current().requestAuthorization(options: unNotificationOptions)
            } catch {
                print("Error getting notification access: \(error)")
                birthdayNotificationsActive = false
            }
        } else {
            birthdayNotificationsActive = false
        }
        await profileManager.scheduleNotifications()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previewContext = CoreDataManager()
    
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(ProfileManager(managedObjectContext: previewContext.container.viewContext))
        }
    }
}
