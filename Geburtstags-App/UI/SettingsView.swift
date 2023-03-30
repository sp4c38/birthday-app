//
//  SettingsView.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 30.03.23.
//

import SwiftUI

struct SettingsView: View {
    @State var notificationsOn = true
    
    var body: some View {
        VStack {
            Toggle(isOn: $notificationsOn) {
                Text("Notifications")
            }
    
            Button(action:  {}) {
                Text("Import from contacts")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .navigationTitle("Settings")
        .padding([.leading, .trailing], 16)
        .padding(.top, 10)
    }
}
