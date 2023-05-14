//
//  WelcomeScreen.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 02.04.23.
//

import Contacts
import SwiftUI

struct WelcomeScreen: View {
    @AppStorage(udImportProfilesFromContactsKey) var importProfilesFromContacts = udImportProfilesFromContactsDefault
    
    @State var contactAccessGranted: Bool? = nil
    @State var showNextScreen: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Spacer(minLength: 50)
                
                VStack {
                    Text("🥳🎂🎁")
                        .font(.system(size: 90))
                        .padding(.bottom, 30)
                    
                    Spacer()
                    Text("Welcome to")
                        .bold()
                        .font(.largeTitle)
                    
                    Text("birthdays")
                        .fontWeight(.heavy)
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 50)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's get you started.")
                        .font(.headline)
                    Text("Please select how you wish to add your birthdays:")
                        .padding(.bottom, 20)
                }
                
                if contactAccessGranted == false {
                    Text("Contact access was declined. Choose \"Add manually\" or allow access in the Settings App.")
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                }
                
                Button(action: {
                    Task { await syncFromContacts() }
                }) {
                    Text("Sync from contacts")
                        .bold()
                        .padding([.top, .bottom], 7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                
                Button(action: { showNextScreen = true }) {
                    Text("Add manually")
                        .padding([.top, .bottom], 7)
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                
                Text("You can still choose to import your birthdays from contacts later on in the settings.")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .navigationDestination(isPresented: $showNextScreen) { WelcomeScreenNotifications() }
    }
    
    func syncFromContacts() async {
        // Get contact access
        let store = CNContactStore()
        do {
            contactAccessGranted = try await store.requestAccess(for: .contacts)
            if contactAccessGranted == true {
                importProfilesFromContacts = true
                showNextScreen = true
            }
        } catch {
            print("Error getting contact access: \(error).")
            contactAccessGranted = false
        }
    }
}

struct WelcomeScreenNotifications: View {
    @AppStorage(udShowWelcomeScreenKey) var showWelcomeScreen = udShowWelcomeScreenDefault
    
    @State var notificationAccessGranted: Bool? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Do you wish to receive notifications for birthdays?")
                .bold()
                .font(.largeTitle)
                .padding(.bottom)
            
            Text("You'll be notified at midnight on the date of each birthday.")
            
            Spacer()
            
            
            if notificationAccessGranted == false {
                Text("Notification access was declined. Choose \"Don't send me notifications\" or allow access in the Settings App.")
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }
            
            Button(action: { Task { await requestNotificationAccess() } }) {
                Text("Send me notifications")
                    .padding([.top, .bottom], 7)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .padding(.bottom)
            
            
            Button(action: {
                showWelcomeScreen = false
            }) {
                Text("Don't send me notifications")
                    .padding([.top, .bottom], 7)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
    }
    
    func requestNotificationAccess() async {
        do {
            notificationAccessGranted = try await UNUserNotificationCenter.current().requestAuthorization(options: unNotificationOptions)
            
            if notificationAccessGranted == true {
                showWelcomeScreen = false
            }
        } catch {
            print("Error requesting notification access: \(error)")
            notificationAccessGranted = false
        }
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WelcomeScreen()
        }
        WelcomeScreenNotifications()
    }
}
