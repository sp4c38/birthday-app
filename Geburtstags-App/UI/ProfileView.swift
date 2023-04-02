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
                case .success(let image):
                    Image(uiImage: image)
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

struct ProfileView: View {
    enum Context {
        case add
        case edit
    }
    
    let context: Context
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    
    @State var imageState: ProfilePictureView.ImageState = .empty
    @State var name: String = ""
    @State var birthday = Date.now
    
    @State var profileSaveFailed: Bool = false
    @State var showPhotoPicker = false
    
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
                
                if context == .edit {
                    Section {
                        VStack(spacing: 20) {
                            Text("🎂 11d 22h 13min 🎂")
                                .bold()
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(context == .edit ? "Edit profile" : "Add profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: saveProfile) }
                
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { presentationMode.wrappedValue.dismiss() }) }
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

                content
            }
        }
    }
    
    func saveProfile() {
        if case .loading = imageState {
            return
        }
        
        let profile = Profile(context: managedObjectContext)
        
        switch imageState {
        case .empty, .failure:
            profile.image = nil
        case .success(let uIImage):
            profile.image = uIImage.jpegData(compressionQuality: 0.8)
        case .loading:
            break
        }
        profile.name = name
        profile.birthday = birthday
        
        do {
            try managedObjectContext.save()
            print("Saved new profile.")
            presentationMode.wrappedValue.dismiss()
        } catch {
            profileSaveFailed = true
            print("Failed saving new profile: \(error as NSError).")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(context: .edit)
        ProfilePictureView(imageState: .constant(.empty))
    }
}
