//
//  Profile+CoreDataClass.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 30.03.23.
//
//

import Foundation
import CoreData

protocol ProfileProtocol: Identifiable {
    var id: UUID { get }
    var name: String? { get }
    var birthday: Date? { get }
    var image: Data? { get }
    
    var nextBirthday: Date? { get }
}

extension ProfileProtocol {
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
}

// Contains contact data imported from the contact app.
struct ContactProfile: ProfileProtocol {
    var id = UUID()
    var contactIdentifier: String
    var name: String?
    var birthday: Date?
    var image: Data?
}

@objc(StoredProfile)
public class StoredProfile: NSManagedObject, ProfileProtocol {
    public var id = UUID()
}
