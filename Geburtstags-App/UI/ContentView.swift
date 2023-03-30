
//  ContentView.swift
//  Geburtstags-App
//
//  Created by Jannes Schäfer on 02.10.22.
//

import SwiftUI

// Countdown: https://catch-questions.com/english/posts/activity1.html

struct ContentView: View {
    init() {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.red]
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(entity: Profile.entity(), sortDescriptors: []) var profiles: FetchedResults<Profile>
    let birthdayDateFormatter = BirthdayRelativeDateFormatter()
    
    @State var showAddProfile = false
    @State var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { profile in
                    Button(action: { showEditProfile = true }) {
                        HStack(alignment: .bottom, spacing: 15) {
                            getProfileImage(from: profile.image)?
                                .resizable()
                                .clipShape(Circle())
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                            
                            Text(getBirthdayCountdown(from: profile))
                                .bold()
                                .font(.title)
                            
                            Text(profile.name ?? "")
                                .baselineOffset(4)
                        }
                        .foregroundColor(.black)
                    }
                }
                .onDelete(perform: deleteProfile)
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
            .sheet(isPresented: $showEditProfile) { ProfileView(context: .edit) }
            .sheet(isPresented: $showAddProfile) { ProfileView(context: .add) }
        }
    }
    
    func getProfileImage(from data: Data?) -> Image? {
        guard let data = data,
              let uiImage = UIImage(data: data)
        else { return nil }
        return Image(uiImage: uiImage)
    }
    
    func getBirthdayCountdown(from profile: Profile) -> String {
        guard let nextBirthday = profile.nextBirthday else { return "NaN" }
        return birthdayDateFormatter.string(for: nextBirthday) ?? "NaN"
    }
    
    func deleteProfile(at indexSet: IndexSet) {
        for i in indexSet {
            let profile = profiles[i]
            managedObjectContext.delete(profile)
        }
        do {
            try managedObjectContext.save()
        } catch {
            print("Couldn't delete profile: \(error).")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
    
