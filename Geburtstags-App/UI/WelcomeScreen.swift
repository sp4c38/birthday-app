//
//  WelcomeScreen.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 02.04.23.
//

import Contacts
import SwiftUI

struct WelcomeScreen: View {
    @AppStorage("showWelcomeScreen") var showWelcomeScreen = true
    @State var contactAccessGranted: Bool? = nil
    
    var body: some View {
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
            
            Button(action: {
                Task { await getContactAccess() }
            }) {
                Text("Sync from contacts")
                    .bold()
                    .padding([.top, .bottom], 7)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            
            if contactAccessGranted == false {
                Text("Contact access was declined. Choose \"Add manually\" or allow access in the Settings App.")
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
            }
            
            Button(action: {
                showWelcomeScreen = false
            }) {
                Text("Add manually on next screen")
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
    
    func getContactAccess() async {
        let store = CNContactStore()
        do {
            contactAccessGranted = try await store.requestAccess(for: .contacts)
            showWelcomeScreen = false
        } catch {
            print("Error getting contact access: \(error).")
            contactAccessGranted = false
        }
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}
