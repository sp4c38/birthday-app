//
//  Profile+CoreDataClass.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 30.03.23.
//
//

import Foundation
import CoreData

@objc(Profile)
public class Profile: NSManagedObject {
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
