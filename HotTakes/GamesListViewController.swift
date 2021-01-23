//
//  ViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import UIKit
import SDWebImage

class GamesListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var games = Games()
    var favoriteTeam: Team!
    var htUser: HTUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Starts app at profile tab
        self.tabBarController?.selectedIndex = 2
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Initializes favorite team
        if favoriteTeam == nil {
            favoriteTeam = Team(id: 0, school: "", mascot: "", abbreviation: "", color: "", alt_color: "", logos: [])
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Updates colors within navigation controller
        updateUserInterface()
        
        // Loads team games and updates table
        self.games.getData(teamName: self.favoriteTeam.school) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

    }
    
    
    // Updates colors and text to reflect favorite team
    func updateUserInterface() {
        
        if favoriteTeam == nil || favoriteTeam.id == 0 {
            return
        }
        
        navigationController?.navigationBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
        if favoriteTeam.alt_color != nil {
            navigationController?.navigationBar.tintColor = UIColor(hex: "\(favoriteTeam.alt_color!)ff")
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(hex: "\(favoriteTeam.alt_color!)ff"), NSAttributedString.Key.font:UIFont(name: "Avenir Next Condensed Demi Bold", size: 30.0)]
        }
        navigationItem.title = favoriteTeam.school.uppercased()
    }
    
    
    // Sends selected game to GameDetailViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowGameDetail" {
            let destination = segue.destination as! GameDetailViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.game = games.gameArray[selectedIndexPath.row]
        }
    }
    
}

extension GamesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.gameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as! GameTableViewCell
        
        // If game has been played, show score
        if games.gameArray[indexPath.row].home_points != nil {
            cell.dateLabel.isHidden = true
            cell.timeLabel.isHidden = true
            cell.homeScoreLabel.text = "\(games.gameArray[indexPath.row].home_points!)"
            cell.awayScoreLabel.text = "\(games.gameArray[indexPath.row].away_points!)"
        }
        
        // If game hasn't played yet, show date and time
        else {
            let date = games.gameArray[indexPath.row].getDate()
            cell.homeScoreLabel.text = ""
            cell.awayScoreLabel.text = ""
            cell.dateLabel.isHidden = false
            cell.timeLabel.isHidden = false
            cell.dateLabel.text = date[3] + " " + date[4]
            cell.timeLabel.text = "\(date[1]):\(Int(date[2]) ?? 0 < 10 ? "0\(date[2])" : date[2]) \(date[0])"
        }
        
        // Display team names
        cell.homeNameLabel.text = games.gameArray[indexPath.row].home_team
        cell.awayNameLabel.text = games.gameArray[indexPath.row].away_team
        
        // Loads and sets team logos
        guard let homeURL = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(games.gameArray[indexPath.row].home_id).png") else {return cell}
        guard let awayURL = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(games.gameArray[indexPath.row].away_id).png") else {return cell}
        cell.homeImageView.sd_setImage(with: homeURL, completed: nil)
        cell.awayImageView.sd_setImage(with: awayURL, completed: nil)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

// Gets UIColor from hex value
extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
