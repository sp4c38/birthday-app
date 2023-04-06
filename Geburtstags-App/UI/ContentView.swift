
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
    
    var profiles: [any ProfileProtocol] {
        var result = [any ProfileProtocol]()
        result.append(contentsOf: profileManager.storedProfiles)
        result.append(contentsOf: profileManager.contactProfiles)
        
        // Sort profiles
        return result.sorted { firstProfile, secondProfile in // Evaluate if input profiles are in increasing order.
            guard let firstNextBirthday = firstProfile.nextBirthday,
                  let secondNextBirthday = secondProfile.nextBirthday else { return true }
            return secondNextBirthday >= firstNextBirthday
        }
    }
    
    let birthdayDateFormatter = BirthdayRelativeDateFormatter()
    
    @State var editProfile: (any ProfileProtocol)? = nil
    @State var showAddProfile = false
    @State var showEditProfile = false
    
    var body: some View {
        List {
            ForEach(profiles, id: \.id) { profile in
                Button(action: { showEditProfile = true }) {
                    HStack(alignment: .center, spacing: 10) {
                        getProfileImage(from: profile.image)?
                            .resizable().scaledToFit().frame(height: 50)
                            .clipShape(Circle())
                        
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
        .sheet(item: $editProfile) { ProfileView(context: .edit) }
//        .sheet(isPresented: $showEditProfile) { ProfileView(context: .edit) }
        .sheet(isPresented: $showAddProfile) { ProfileView(context: .add) }
        .navigationBarBackButtonHidden()
        .onChange(of: scenePhase) { if $0 == .active { profileManager.collectProfiles() } }
    }
    
    func getProfileImage(from data: Data?) -> Image? {
        guard let data = data,
              let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }
    
    func getBirthdayCountdown<T: ProfileProtocol>(from profile: T) -> String {
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
    
