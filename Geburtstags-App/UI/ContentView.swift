
//  ContentView.swift
//  Geburtstags-App
//
//  Created by Jannes Schäfer on 02.10.22.
//

import CoreData
import SwiftUI

struct BirthdaysListEntry: View {
    let profile: Profile
    
    let birthdayDateFormatter = BirthdayRelativeDateFormatter()
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .hidden()
                .overlay {
                    ((profile.image != nil) ? Image(uiImage: profile.image!) : Image(systemName: "person.crop.circle"))
                        .resizable()
                        .scaledToFill()
                        .font(.body.weight(.thin))
                        .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.67))
                }
                .clipShape(Circle())
                .frame(width: 50, height: 50)
            
            Text(birthdayDateFormatter.short(date: profile.nextBirthday))
                .bold()
                .font(.title)
            
            Text(profile.name)
                .baselineOffset(-3)
            
            Spacer()
        }
    }
}

struct ContentView: View {
    init() {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.red]
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var profileManager: ProfileManager
    
    @State var editProfile: Profile? = nil
    @State var showAddProfile = false
    
    var body: some View {
        List {
            ForEach(profileManager.profiles) { profile in
                BirthdaysListEntry(profile: profile)
                    .onTapGesture { editProfile = profile }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("birthdays")
        .toolbar {
            ToolbarItem {
                NavigationLink(destination: SettingsView()) { Image(systemName: "gear") }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button(action: { showAddProfile = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editProfile) { ProfileView(profile: $0) }
        .sheet(isPresented: $showAddProfile) { ModifyProfileView() }
        .navigationBarBackButtonHidden()
        .onChange(of: scenePhase) { if $0 == .active { profileManager.collectProfiles() } }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previewContext = CoreDataManager()
    
    static var previews: some View {
        BirthdaysListEntry(profile: .previewProfile(previewContext: previewContext.container.viewContext))
    }
}
    
