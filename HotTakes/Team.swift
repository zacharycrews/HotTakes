//
//  Team.swift
//  HotTakes
//
//  Created by Zach Crews on 12/3/20.
//

import Foundation

struct Team: Codable {
    var id: Int
    var school: String
    var mascot: String
    var abbreviation: String
    var color: String
    var alt_color: String?
    var logos: [String]
    
}
