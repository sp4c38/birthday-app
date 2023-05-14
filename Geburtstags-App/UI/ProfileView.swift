//
//  ProfileView.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 17.10.22.
//

import CoreData
import PhotosUI
import SwiftUI

struct ProfilePictureView: View {
    enum ImageState {
        case empty
        case loading
        case success(UIImage)
        case failure
    }
    
    @Binding var imageState: ImageState
    @State private var imageSelection: PhotosPickerItem? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            switch imageState {
            case .success(let uiImage):
                Image(uiImage: uiImage)
                    .resizable().scaledToFit().frame(height: 150)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            case .failure:
                Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                    .resizable().scaledToFit().frame(height: 150)
                    .symbolRenderingMode(.multicolor)
                    .foregroundColor(.gray)
                    
                Text("Couldn't load image.")
                    .padding(.top, 2)
            default:
                Image(systemName: "person.circle.fill")
                    .resizable().scaledToFit().frame(height: 150)
                    .foregroundColor(.gray)
            }
            
            Button(action: {}) {
                switch imageState {
                case .empty, .failure:
                    Text("Add photo")
                default:
                    Text("Edit photo")
                }
            }
            .buttonStyle(DefaultButtonStyle())
        }
        .overlay {
            PhotosPicker(selection: $imageSelection, matching: .images, photoLibrary: .shared()) {
                Color.clear
            }
            .onChange(of: imageSelection) { newSelection in
                if let imageSelection = imageSelection {
                    loadTransferable(from: imageSelection)
                    imageState = .loading
                }
            }
        }
    }
    
    func loadTransferable(from imageSelection: PhotosPickerItem) {
        // Need to use Data type, can't use Image. Image conforms to Transferable, but can only represent the Image from Photos if it's a PNG file. After Data has been received, it's converted to an UIImage, then to an Image.
        imageSelection.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("The loaded image isn't the currently requested image.")
                    return
                }

                switch result {
                case .success(let imageData?):
                    guard let uiImage = UIImage(data: imageData) else {
                        self.imageState = .failure
                        return
                    }
                    self.imageState = .success(uiImage)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    print("Issue transfering the profile picture from Photos to the app: \(error).")
                    self.imageState = .failure
                }
            }
        }
    }
}

fileprivate struct ContactManagedByContactApp: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Profile is managed via the Contact App")
                .bold()
                .font(.title)
                .multilineTextAlignment(.center)
            
            Text("We import the profile details of the corresponding contact from the Contact App.\n\nPlease change the data inside the Contact App and return to this app.")
                .font(.body)
            
            Spacer()
        }
        .padding()
    }
}

struct ModifyProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profileManager: ProfileManager
    
    let profile: Profile?
    @State var name: String
    @State var birthday: Date
    @State var imageState: ProfilePictureView.ImageState
    
    @Binding var profileWasDeleted: Bool
    @State var databaseSaveFailed: Bool = false
    @State var showPhotoPicker = false
    
    init(profile profileParsed: Profile? = nil, profileWasDeleted: Binding<Bool> = .constant(false)) {
        self.profile = profileParsed
        _name = State(initialValue: profileParsed?.name ?? "")
        _birthday = State(initialValue: profileParsed?.birthday ?? Date.now)
        if let image = profileParsed?.image {
            _imageState = State(initialValue: .success(image))
        } else {
            _imageState = State(initialValue: .empty)
        }
        self._profileWasDeleted = profileWasDeleted
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    ProfilePictureView(imageState: $imageState)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                
                    Section {
                        TextField("Name", text: $name)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            
                            DatePicker(
                                "Birthday",
                                selection: $birthday,
                                in: ...Date.now,
                                displayedComponents: [.date])
                        }
                    }
                    
                    if profile != nil {
                        Button(action: deleteProfile) {
                            Text("Delete profile")
                                .padding(5)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.61, green: 0.14, blue: 0.11, opacity: 1.0))
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
                .alert("Database Error", isPresented: $databaseSaveFailed) {
                    Button("Ok", role: .cancel) { presentationMode.wrappedValue.dismiss() }
                } message: {
                    Text("Couldn't perform this operation.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: saveProfile) }
                
                if profile == nil {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { presentationMode.wrappedValue.dismiss() }) }
                }
            }
            .navigationTitle(profile == nil ? "Add profile" : "Edit profile")
        }
    }
    
    func saveProfile() {
        if case .loading = imageState {
            return
        }
        
        var uiImage: UIImage?
        switch imageState {
        case .success(let selectedUIImage):
            uiImage = selectedUIImage
        default:
            uiImage = nil
        }
        
        if let profile = profile {
            print("Updating profile.")
            profile.name = name
            profile.birthday = birthday
            profile.image = uiImage
        } else {
            print("Saved new profile.")
            _ = Profile(context: managedObjectContext,
                        identifier: UUID().uuidString,
                        name: name,
                        birthday: birthday,
                        image: uiImage,
                        type: .storedProfile)
        }
        
        do {
            try managedObjectContext.save()
            profileManager.collectProfiles()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed saving new profile: \(error).")
            databaseSaveFailed = true
        }
    }
    
    func deleteProfile() {
        guard let profile = profile else { return }
        managedObjectContext.delete(profile)
        profileWasDeleted = true
        profileManager.collectProfiles()
        presentationMode.wrappedValue.dismiss()
    }
}

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var profile: Profile
    let formatter = BirthdayRelativeDateFormatter()
    let displayComponents: [Calendar.Component] = [.month, .day, .hour, .minute, .second]
    @State var showEditProfile = false
    @State var profileWasDeleted = false
    @State var databaseSaveFailed = false
    
    @State var selectedComponent: Calendar.Component = .day
    var difference: (value: String, unit: String) {
        return formatter.difference(date: profile.nextBirthday, component: selectedComponent)
    }
    
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: Date(), by: 1)) { _ in
                Form {
                    // Single element time until birthday
                    Section {
                        VStack {
                            Picker("Test", selection: $selectedComponent) {
                                Text("Months").tag(Calendar.Component.month)
                                Text("Weeks").tag(Calendar.Component.weekOfYear)
                                Text("Days").tag(Calendar.Component.day)
                                Text("Hours").tag(Calendar.Component.hour)
                                Text("Mins").tag(Calendar.Component.minute)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom, 10)
                            
                            VStack {
                                Text(difference.value.description)
                                    .bold()
                                    .font(.title)
                                    .textSelection(.enabled)
                                
                                Text(difference.unit)
                                    .baselineOffset(-6)
                            }
                        }
                    }
                    
                    // Multi element time until birthday
                    Section {
                        ForEach(formatter.difference(date: profile.nextBirthday), id: \.unit) { difference in
                            HStack(alignment: .center) {
                                Text(difference.value)
                                    .bold()
                                    .font(.title)
                                
                                Text(difference.unit)
                                    .baselineOffset(-4)
                            }
                        }
                    }
                }
                .navigationTitle(profile.name)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Done", action: { presentationMode.wrappedValue.dismiss() }) }
                }
                .sheet(isPresented: $showEditProfile, onDismiss: {
                    if profileWasDeleted {
                        presentationMode.wrappedValue.dismiss()
                        do {
                            try managedObjectContext.save()
                        } catch {
                            print("Failed deleting profile: \(error).")
                            databaseSaveFailed = true
                        }
                    }
                }) {
                    ModifyProfileView(profile: profile, profileWasDeleted: $profileWasDeleted)
                }
                .alert("Database Error", isPresented: $databaseSaveFailed) {
                    Button("Ok", role: .cancel) { presentationMode.wrappedValue.dismiss() }
                } message: {
                    Text("Couldn't perform this operation.")
                }
                
                VStack {
                    if case .contactProfile = profile.type {
                        HStack {
                            Text("To edit this profile, please edit it in the Contacts App.")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        Button(action: { showEditProfile = true }) {
                            Text("Edit profile")
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                }
                .padding([.leading, .trailing], 25)
            }
            .background(colorScheme == .light ? Color(red: 0.95, green: 0.95, blue: 0.97) : Color.black)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previewContext = CoreDataManager()
    
    static var previews: some View {
        ProfileView(profile: Profile.previewProfile(previewContext: previewContext.container.viewContext))
//        ModifyProfileView(profile: Profile.previewProfile(previewContext: previewContext.container.viewContext))
//        ContactManagedByContactApp()
//        ProfilePictureView(imageState: .constant(.empty))
    }
}
