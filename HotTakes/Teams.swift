//
//  Teams.swift
//  HotTakes
//
//  Created by Zach Crews on 12/3/20.
//

import Foundation

class Teams {
    var teamArray: [Team] = []
    var urlString = "https://api.collegefootballdata.com/teams/fbs?year=2020"
    
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
                self.teamArray = try JSONDecoder().decode([Team].self, from: data!)
            } catch {
                print("JSON ERROR: \(error)")
            }
            completed()
        }
        task.resume()
    }
    
}
