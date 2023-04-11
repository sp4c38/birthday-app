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
            return "\(days) \(getUnitName(for: .day, value: days))"
        } else if hours > 2 {
            return "\(hours) \(getUnitName(for: .hour, value: hours))"
        } else if minutes > 2 {
            return "\(minutes) \(getUnitName(for: .minute, value: minutes))"
        } else {
            return "\(seconds) \(getUnitName(for: .second, value: seconds))"
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
            return (differenceString, getUnitName(for: .month, value: difference))
        case .day:
            return (differenceString, getUnitName(for: .day, value: difference))
        case .hour:
            return (differenceString, getUnitName(for: .hour, value: difference))
        case .minute:
            return (differenceString, getUnitName(for: .minute, value: difference))
        case .second:
            return (differenceString, getUnitName(for: .second, value: difference))
        default:
            return defaultReturn
        }
    }
    
    func difference(date: Date) -> [(value: String, unit: String)] {
        let calendar = Calendar.current
        let now = Date()
        let collectComponents: [Calendar.Component] = [.month, .day, .hour, .minute, .second]
        let dateDifference = calendar.dateComponents(Set(collectComponents), from: now, to: date)
        
        var result = [(value: String, unit: String)]()
        for component in collectComponents {
            let value = dateDifference.value(for: component)!
            result.append(
                (value: "\(value)", unit: getUnitName(for: component, value: value))
            )
        }
        return result
    }
    
    func getUnitName(for component: Calendar.Component, value: Int) -> String {
        switch component {
        case .month:
            return value != 1 ? "months" : "month"
        case .day:
            return value != 1 ? "days" : "day"
        case .hour:
            return value != 1 ? "hours" : "hour"
        case .minute:
            return value != 1 ? "minutes" : "minute"
        case .second:
            return value != 1 ? "seconds" : "second"
        case .nanosecond:
            return value != 1 ? "nanoseconds" : "nanosecond"
        default:
            return "NaN"
        }
    }
}
