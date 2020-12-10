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
}
