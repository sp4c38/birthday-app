
//  ContentView.swift
//  Geburtstags-App
//
//  Created by Jannes Schäfer on 02.10.22.
//

import CoreData
import SwiftUI

// Countdown: https://catch-questions.com/english/posts/activity1.html

struct ContentView: View {
    init() {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.red]
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var profileManager: ProfileManager

    let birthdayDateFormatter = BirthdayRelativeDateFormatter()
    
    @State var editProfile: Profile? = nil
    @State var showAddProfile = false
    
    var body: some View {
        List {
            ForEach(profileManager.profiles) { profile in
                Button(action: { editProfile = profile }) {
                    HStack(alignment: .center, spacing: 10) {
                        if let profileImage = profile.image {
                            Image(uiImage: profileImage)
                                .resizable().scaledToFit().frame(height: 50)
                                .clipShape(Circle())
                        }
                        
                        Text(getBirthdayCountdown(from: profile))
                            .bold()
                            .font(.title)
                        
                        Text(profile.name ?? "")
                            .baselineOffset(-3)
                        
                        Spacer()
                    }
                    .foregroundColor(.black)
                }
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
        .sheet(isPresented: $showAddProfile) { ProfileView() }
        .navigationBarBackButtonHidden()
        .onChange(of: scenePhase) { if $0 == .active { profileManager.collectProfiles() } }
    }
    
    func getBirthdayCountdown(from profile: Profile) -> String {
        guard let nextBirthday = profile.nextBirthday else { return "NaN" }
        return birthdayDateFormatter.string(for: nextBirthday) ?? "NaN"
    }
    
//    func deleteProfile(at indexSet: IndexSet) {
//        for i in indexSet {
//            guard let profile = profileManager.profiles[i] as? StoredProfile else { continue }
//            managedObjectContext.delete(profile)
//        }
//        do {
//            try managedObjectContext.save()
//        } catch {
//            print("Couldn't delete profile: \(error).")
//        }
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
    
