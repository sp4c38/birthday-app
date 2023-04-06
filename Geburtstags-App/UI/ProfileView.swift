//
//  ProfileView.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 17.10.22.
//

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
        VStack(spacing: 30) {
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
        VStack(spacing: 30) {
            Text("Profile is managed via the Contact App")
                .bold()
                .font(.title)
                .multilineTextAlignment(.center)
            
            Text("We import the profile details of the corresponding contact from the Contact App. Please change the data inside the Contact App and return to this app.")
                .font(.body)
            
            Spacer()
        }
        .padding()
    }
}

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var profileManager: ProfileManager
    
    let profile: Profile?
    
    @State var name: String
    @State var birthday: Date
    @State var imageState: ProfilePictureView.ImageState
    
    @State var profileSaveFailed: Bool = false
    @State var showPhotoPicker = false
    
    init(profile profileParsed: Profile? = nil) {
        self.profile = profileParsed
        _name = State(initialValue: profileParsed?.name ?? "")
        _birthday = State(initialValue: profileParsed?.birthday ?? Date.now)
        if let image = profileParsed?.image {
            _imageState = State(initialValue: .success(image))
        } else {
            _imageState = State(initialValue: .empty)
        }
    }
    
    var content: some View {
        VStack {
            ProfilePictureView(imageState: $imageState)
            
            Form {
                
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
                
                Section {
                    VStack(spacing: 20) {
                        Text("🎂 11d 22h 13min 🎂 (Dieser detailierte Counter funktioniert noch nicht)")
                            .bold()
                            .font(.system(size: 30))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .alert("Database Error", isPresented: $profileSaveFailed) {
                Button("Ok", role: .cancel) { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text("Couldn't save new profile.")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if colorScheme == .light {
                    Color(red: 0.95, green: 0.95, blue: 0.97)
                        .ignoresSafeArea()
                } else {
                    Color.black
                }

                if let profile,
                   case .contactProfile(_) = profile.type {
                    ContactManagedByContactApp()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) { Button("Understood", action: saveProfile) }
                        }
                } else {
                    content
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) { Button("Save", action: saveProfile) }
                            
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { presentationMode.wrappedValue.dismiss() }) }
                        
                        }
                        .navigationTitle(profile == nil ? "Add profile" : "Edit profile")
                }
            }
        }
    }
    
    func saveProfile() {
        if case .loading = imageState {
            return
        }
        
        let profileToSave: Profile
        
        if let profile = profile {
            print("Updating profile.")
            profileToSave = profile
        } else {
            print("Saved new profile.")
            profileToSave = Profile(context: managedObjectContext)
        }
            
        switch imageState {
        case .empty, .failure:
            profileToSave.imageData = nil
        case .success(let uiImage):
            profileToSave.image = uiImage
        case .loading:
            break
        }
        profileToSave.name = name
        profileToSave.birthday = birthday
        
        do {
            try managedObjectContext.save()
            profileManager.collectProfiles()
            presentationMode.wrappedValue.dismiss()
        } catch {
            profileSaveFailed = true
            print("Failed saving new profile: \(error as NSError).")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
//        ProfileView(context: .edit)
        ContactManagedByContactApp()
        ProfilePictureView(imageState: .constant(.empty))
    }
}
