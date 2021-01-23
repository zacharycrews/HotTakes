//
//  GameData.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import Foundation


struct Game: Codable {
    var home_team: String
    var away_team: String
    var home_points: Int?
    var away_points: Int?
    var home_id: Int
    var away_id: Int
    var start_date: String
    var id: Int
    
    // Helper function to parse non-standard API date
    func getDate() -> [String] {
        
        // Parses string
        let dateArray = Array(start_date)
        let monthDict = ["8": "Aug", "9": "Sep", "10": "Oct", "11": "Nov", "12": "Dec", "1" : "Jan"]
        var amPM: String
        var hour = Int("\(dateArray[11])\(dateArray[12])") ?? 12
        var minute = Int("\(dateArray[14])\(dateArray[15])") ?? 0
        var month = Int("\(dateArray[5])\(dateArray[6])") ?? 8
        var day = Int("\(dateArray[8])\(dateArray[9])") ?? 31
        
        // Time zone conversion
        hour -= 5
        if hour <= 0 {
            day -= 1
            hour += 24
        }
        
        // Find if time is AM or PM
        if hour > 12 {
            hour -= 12
            amPM = "PM"
        } else {
            amPM = (hour == 12) ? "PM" : "AM"
        }
        
        let monthStr = monthDict["\(month)"] ?? ""
        return [amPM, "\(hour)", "\(minute)", monthStr, "\(day)"]
    }
}
