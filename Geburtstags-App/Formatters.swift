//
//  Formatters.swift
//  Geburtstags-App
//
//  Created by Léon Becker on 14.10.22.
//

import Foundation

class BirthdayRelativeDateFormatter {
    func short(date: Date) -> String {
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
    
    func difference(date: Date, component: Calendar.Component) -> (value: String, unit: String) {
        let defaultReturn = ("0", "NaN")
        
        let calendar = Calendar.current
        let now = Date()
        let dateDifference = calendar.dateComponents([component], from: now, to: date)
        let difference = dateDifference.value(for: component)!
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        guard let differenceString = numberFormatter.string(from: NSNumber(integerLiteral: difference)) else { return defaultReturn }
        
        switch component {
        case .month:
            return (differenceString, difference != 1 ? "months" : "month")
        case .day:
            return (differenceString, difference != 1 ? "days" : "day")
        case .hour:
            return (differenceString, difference != 1 ? "hours" : "hour")
        case .minute:
            return (differenceString, difference != 1 ? "minutes" : "minute")
        case .second:
            return (differenceString, difference != 1 ? "seconds" : "second")
        case .nanosecond:
            return (differenceString, difference != 1 ? "nanoseconds" : "nanosecond")
        default:
            return defaultReturn
        }
    }
}
