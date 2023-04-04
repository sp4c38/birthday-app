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
        let now = Date()
        let dateDifference = calendar.dateComponents([.day, .hour, .minute, .second], from: now, to: date)
        
        // TODO: There is no live updating of the time inside of the view yet.
        let days = dateDifference.day!
        let hours = dateDifference.hour!
        let minutes = dateDifference.minute!
        let seconds = dateDifference.second!
        
        if days <= 0 && hours <= 0 && minutes <= 0 && seconds <= 0 {
            return "🥳 Happy Birthday"
        } else if days > 2 {
            return "\(days) days"
        } else if hours > 2 {
            return "\(hours) hours"
        } else if minutes > 2 {
            return "\(minutes) minutes"
        } else {
            return "\(seconds) seconds"
        }
    }
}
