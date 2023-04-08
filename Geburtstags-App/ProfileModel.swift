//
//  Profile+CoreDataClass.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 30.03.23.
//
//

import CoreData
import Foundation
import SwiftUI

enum ProfileType {
    case contactProfile(identifier: String)
    case storedProfile
}

@objc(Profile)
public class Profile: NSManagedObject {
    var type: ProfileType = .storedProfile
    
    var nextBirthday: Date? {
        guard let birthday = birthday else { return nil }
        
        let calendar = Calendar.current
        let midnightToday = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: midnightToday)

        var components = calendar.dateComponents([.year, .month, .day], from: birthday)
        components.year = currentYear
        var upcomingBirthday = calendar.date(from: components)! // The upcoming birthday.

        if upcomingBirthday < midnightToday {
            components.year = currentYear + 1
            upcomingBirthday = calendar.date(from: components)!
        }

        return upcomingBirthday
    }
    
    var image: UIImage? {
        get {
            guard let imageData = imageData,
                  let uiImage = UIImage(data: imageData)
            else { return nil }
            
            return uiImage
        }
            
        set {
            guard let uiImage = newValue else { return }
            imageData = uiImage.jpegData(compressionQuality: 0.8)
        }
    }
    
    static func previewProfile(previewContext: NSManagedObjectContext) -> Profile {
        let profile = Profile(context: previewContext)
        profile.name = "Test Profile Name"
        profile.birthday = Date(timeIntervalSince1970: 1138316400)
        profile.imageData = UIImage(systemName: "arrow.up.doc.on.clipboard")?.jpegData(compressionQuality: 0.8)
        return profile
    }
}
