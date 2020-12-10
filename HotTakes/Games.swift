//
//  Games.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import Foundation

class Games {
    var gameArray: [Game] = []
    var urlString = "https://api.collegefootballdata.com/games?year=2020&team=Boston%20College"
    
    func getData(teamName: String, completed: @escaping()->()) {
        let teamString = teamName.replacingOccurrences(of: " ", with: "%20")
        urlString = "https://api.collegefootballdata.com/games?year=2020&team=\(teamString)"
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
                self.gameArray = try JSONDecoder().decode([Game].self, from: data!)
            } catch {
                print("JSON ERROR: \(error.localizedDescription)")
            }
            completed()
        }
        task.resume()
    }
}
