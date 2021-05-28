//
//  OpenIMDateFormatter.swift
//  OpenIMUI
//
//  Created by Snow on 2021/5/25.
//

import Foundation

public class OpenIMDateFormatter {
    
    public static let shared = OpenIMDateFormatter()
    
    private init() {}

    private let formatter = DateFormatter()
    
    public func format(_ interval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: interval)
        var prefix = ""
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            prefix = LocalizedString("Yesterday") + " "
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "YYYY/MM/dd"
        }
        
        return prefix + formatter.string(from: date)
    }
    
}
