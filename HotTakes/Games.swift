//
//  Games.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import Foundation

class Games {
    var gameArray: [Game] = []
    
    func getData(teamName: String, completed: @escaping()->()) {
        let teamString = teamName.replacingOccurrences(of: " ", with: "%20")
        let urlString = "https://api.collegefootballdata.com/games?year=2020&team=\(teamString)"
        guard let url = URL(string: urlString) else {
            print("ERROR: Couldn't create a URL from \(urlString)")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(APIKeys.cfbKey)", forHTTPHeaderField:"Authorization")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("ERROR: \(error)")
            }
            
            do {
                self.gameArray = try JSONDecoder().decode([Game].self, from: data ?? Data())
            } catch {
                print("GAMES JSON ERROR: \(error)")
            }
            completed()
        }
        task.resume()
    }
}
