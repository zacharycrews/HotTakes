//
//  GameDetailViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import UIKit

class GameDetailViewController: UIViewController {
    @IBOutlet weak var awayImageView: UIImageView!
    @IBOutlet weak var homeImageView: UIImageView!
    @IBOutlet weak var awayScoreLabel: UILabel!
    @IBOutlet weak var homeScoreLabel: UILabel!
    @IBOutlet weak var awayNameLabel: UILabel!
    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    var game: Game!
    var gameData: GameDetail!
    
    var homeIndex: Int!
    var awayIndex: Int!
    
    // Stat variable names and their English translation
    let statTerms = ["rushingTDs": "Rushing TDs", "completionAttempts": "Comp/Att", "netPassingYards": "Passing Yds", "passingTDs": "Passing TDs", "rushingAttempts": "Rushing Attempts", "rushingYards": "Rushing Yds", "yardsPerRushAttempt": "Yards per Rush", "fourthDownEff": "4th Down Efficiency", "possessionTime": "Possession Time", "tackles": "Tackles", "sacks": "Sacks", "turnovers": "Turnovers"]
    
    // Stats to be included in the table
    let wantedStats = ["completionAttempts", "netPassingYards", "passingTDs",  "rushingAttempts", "rushingYards", "yardsPerRushAttempt", "rushingTDs", "fourthDownEff", "possessionTime", "tackles", "sacks", "turnovers"]
    
    // Stats that will be bolded if the number is higher
    let goodStats = ["rushingTDs", "netPassingYards", "passingTDs", "rushingAttempts", "rushingYards", "yardsPerRushAttempt", "tackles", "sacks"]
    
    var homeURL: URL!
    var awayURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Game should never be nil, but initializes just in case
        if game == nil {
            game = Game(home_team: "", away_team: "", home_points: 0, away_points: 0, home_id: 0, away_id: 0, start_date: "", id: 0)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // If game hasn't been played yet
        if game.home_points == nil {
            tableView.isHidden = true
            updateUserInterface()
            return
        }
        
        // Get game data from API, update UI
        gameData = GameDetail(id: game.id)
        gameData.getData {
            if self.gameData.teamStats[0].homeAway == "home" {
                self.homeIndex = 0
            } else {
                self.homeIndex = 1
            }
            self.awayIndex = 1 - self.homeIndex
            
            DispatchQueue.main.async {
                self.updateUserInterface()
            }
        }
    }
    
    
    func updateUserInterface() {
        
        // If game has been played, show the score
        if game.home_points != nil {
            self.awayScoreLabel.text = "\(self.game.away_points!)"
            self.homeScoreLabel.text = "\(self.game.home_points!)"
        }
        
        // Else, hide the stats table and show when the game will be played
        else {
            self.awayScoreLabel.isHidden = true
            self.homeScoreLabel.isHidden = true
            self.timeLabel.isHidden = false
            self.dateLabel.isHidden = false
            let date = game.getDate()
            self.dateLabel.text = date[3] + " " + date[4]
            self.timeLabel.text = "\(date[1]):\(Int(date[2]) ?? 0 < 10 ? "0\(date[2])" : date[2]) \(date[0])"
        }
        
        // Updates team name labels
        self.awayNameLabel.text = self.game.away_team
        self.homeNameLabel.text = self.game.home_team
        
        // Updates team logos
        guard let homeURL = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(game.home_id).png") else {return}
        guard let awayURL = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(game.away_id).png") else {return}
        homeImageView.sd_setImage(with: homeURL, completed: nil)
        awayImageView.sd_setImage(with: awayURL, completed: nil)
        
        tableView.reloadData()
    }
    
}

extension GameDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wantedStats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatCell", for: indexPath) as! GameDataTableViewCell
        
        if homeIndex == nil || game.home_points == nil {
            return cell
        }
        
        // Get stat to be displayed
        let stat = wantedStats[indexPath.row]
        cell.statNameLabel.text = statTerms[stat]
        
        // Linear search for home and away stat
        var ctr = 0
        while ctr < gameData.teamStats[homeIndex].stats.count - 1 && gameData.teamStats[homeIndex].stats[ctr].category != stat {
            ctr += 1
        }
        let homeStat = gameData.teamStats[homeIndex].stats[ctr].category == stat ? gameData.teamStats[homeIndex].stats[ctr].stat : "-"
        
        ctr = 0
        while ctr < gameData.teamStats[homeIndex].stats.count - 1 && gameData.teamStats[awayIndex].stats[ctr].category != stat {
            ctr += 1
        }
        let awayStat = gameData.teamStats[awayIndex].stats[ctr].category == stat ? gameData.teamStats[awayIndex].stats[ctr].stat : "-"
        
        // Updates stat labels
        cell.homeStatLabel.text = homeStat
        cell.awayStatLabel.text = awayStat
        cell.homeStatLabel.font = UIFont.systemFont(ofSize: 32.0)
        cell.awayStatLabel.font = UIFont.systemFont(ofSize: 32.0)
        
        // Checks numbers and stat category to determine which to bold
        if goodStats.contains(stat) {
            if Double(homeStat) ?? 0.0 > Double(awayStat) ?? 0.0 {
                cell.homeStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            } else if Double(homeStat) ?? 0.0 < Double(awayStat) ?? 0.0 {
                cell.awayStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            }
        } else if stat == "turnovers" {
            if Int(homeStat) ?? 0 > Int(awayStat) ?? 0 {
                cell.awayStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            }
        } else if stat == "completionAttempts" {
            let homePct = (Double(homeStat.prefix(2)) ?? 0) / (Double(homeStat.suffix(2)) ?? 1)
            let awayPct = (Double(awayStat.prefix(2)) ?? 0) / (Double(awayStat.suffix(2)) ?? 1)
            if homePct > awayPct {
                cell.homeStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            } else {
                cell.awayStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            }
        } else if stat == "possessionTime" {
            if Int(homeStat.prefix(2)) ?? 0 > Int(awayStat.prefix(2)) ?? 0 {
                cell.homeStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            } else if Int(homeStat.prefix(2)) ?? 0 < Int(awayStat.prefix(2)) ?? 0 {
                cell.awayStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            } else if Int(homeStat.suffix(2)) ?? 0 > Int(awayStat.suffix(2)) ?? 0 {
                cell.homeStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            } else {
                cell.awayStatLabel.font = UIFont.boldSystemFont(ofSize: 32.0)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
