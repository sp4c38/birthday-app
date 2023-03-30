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
        let dateDifference = calendar.dateComponents([.month, .day, .hour, .minute], from: Date.now, to: date)
        
        let month = dateDifference.month!
        let days = dateDifference.day!
        let hours = dateDifference.hour!
        let minutes = dateDifference.minute!

        if month >= 1 {
            return "\(month) month"
        } else if days >= 1 {
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
