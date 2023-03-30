//
//  Formatters.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 14.10.22.
//

import Foundation

class BirthdayRelativeDateFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let date = obj as? Date else { return nil }
        
        let calendar = Calendar.current
        let midnightToday = calendar.startOfDay(for: Date())
        
        let dateDifference = calendar.dateComponents([.day, .hour, .minute], from: midnightToday, to: date)
        
        let days = dateDifference.day!
        let hours = dateDifference.hour!
        let minutes = dateDifference.minute!

        if days >= 1 {
            return "\(days) " + (days > 1 ? "days" : "day")
        } else if hours >= 1 {
            return "\(hours) " + (hours > 1 ? "hours" : "hour")
        } else if minutes >= 1 {
            return "\(minutes) " + (minutes > 1 ? "minutes" : "minute")
        } else {
            return "NaN"
        }
    }
}
