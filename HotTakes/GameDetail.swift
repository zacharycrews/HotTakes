//
//  GameDetail.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import Foundation


class GameDetail {
    
    private struct Returned: Codable {
        var teams: [TeamData]
    }
    
    struct TeamData: Codable {
        var school: String
        var homeAway: String
        var stats: [Stat]
    }
    
    struct Stat: Codable {
        var category: String
        var stat: String
    }
    
    var gameID: Int!
    var urlString: String!
    
    var teamStats: [TeamData] = []
    
    init(id: Int) {
        gameID = id
        urlString = "https://api.collegefootballdata.com/games/teams?year=2020&gameId=\(gameID!)"
    }
    
    func getData(completed: @escaping()->()) {
        guard let url = URL(string: urlString) else {
            print("ERROR: Couldn't create a URL from \(urlString)")
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
            }
            
            do {
                let returned = try JSONDecoder().decode([Returned].self, from: data!)
                self.teamStats = returned[0].teams
            } catch {
                print("JSON ERROR: \(error)")
            }
            completed()
        }
        task.resume()
    }
    

}
