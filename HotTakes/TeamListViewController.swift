//
//  TeamListViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/3/20.
//

import UIKit
import SDWebImage

class TeamListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var teams = Teams()
    var selectedTeam: Team!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        teams.getData {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if selectedTeam == nil {
            self.navigationItem.setHidesBackButton(true, animated: true)
        } else {
            self.navigationItem.setHidesBackButton(false , animated: true)
        }
    }
    
}

extension TeamListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.teamArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCell", for: indexPath) as! TeamTableViewCell
        cell.teamNameLabel.text = "\(teams.teamArray[indexPath.row].school) \(teams.teamArray[indexPath.row].mascot)"
        guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(teams.teamArray[indexPath.row].id).png") else {return cell}
        do {
            let data = try Data(contentsOf: url)
            cell.imageView?.image = UIImage(data: data)
        } catch {
            print("ERROR: error thrown trying to get image from url \(url)")
        }
        //cell.teamImageView.sd_setImage(with: url, completed: nil)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}
