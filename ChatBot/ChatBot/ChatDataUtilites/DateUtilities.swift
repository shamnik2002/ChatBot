//
//  DateUtilities.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/18/25.
//

import Foundation

fileprivate var shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

fileprivate var monthDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter
}()

fileprivate var dayDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "E d"
    return formatter
}()

extension Date {
    /// Relative date e.g today, for any date in the last week Sun 2, dates beyond last week show Oct 30, and beyond current year show 1/12/2024
    func shortRelativeDate() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        let currentDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        if components.year != currentDate.year {
            return shortDateFormatter.string(from: self)
        }
        if (currentDate.day ?? 0) - (components.day ?? 0) >= 7 {
            return monthDateFormatter.string(from: self)
        }
        if currentDate.day != components.day {
            return dayDateFormatter.string(from: self)
        }
        return "today"
    }
}
