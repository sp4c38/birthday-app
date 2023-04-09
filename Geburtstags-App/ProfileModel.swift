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
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }
    
    @NSManaged public var name: String
    @NSManaged public var birthday: Date
    @NSManaged public var imageData: Data?
    var type: ProfileType = .storedProfile
    
    var nextBirthday: Date {
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
            guard let uiImage = newValue else {
                imageData = nil
                return
            }
            imageData = uiImage.jpegData(compressionQuality: 0.8)
        }
    }
    
    static func previewProfile(previewContext: NSManagedObjectContext) -> Profile {
        Profile(context: previewContext,
                              name: "Test Profile Name",
                              birthday: Date(timeIntervalSince1970: 1138316400),
                              image: UIImage(systemName: "arrow.up.doc.on.clipboard"),
                              type: .storedProfile
        )
    }

    // To avoid unneeded optional values these steps were followed: https://www.jessesquires.com/blog/2022/01/26/core-data-optionals/
    init(context: NSManagedObjectContext, name: String, birthday: Date, image: UIImage?, imageData: Data? = nil, type: ProfileType) {
        let entity = NSEntityDescription.entity(forEntityName: "Profile", in: context)!
         
        super.init(entity: entity, insertInto: context)
        self.name = name
        self.birthday = birthday
        self.image = image
        self.imageData = imageData
        self.type = type
    }

    @objc
    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    @available(*, unavailable)
    public init() {
        fatalError("\(#function) not implemented")
    }
    
    @available(*, unavailable)
    public convenience init(context: NSManagedObjectContext) {
        fatalError("\(#function) not implemented")
    }
}

extension Profile : Identifiable {

}
