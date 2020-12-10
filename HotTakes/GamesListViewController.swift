//
//  ViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/2/20.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseUI
import GoogleSignIn
import SDWebImage

class GamesListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var games = Games()
    
    var favoriteTeam: Team!
    
    var authUI: FUIAuth!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        
        if favoriteTeam == nil {
            favoriteTeam = Team(id: 0, school: "", mascot: "", abbreviation: "", color: "", alt_color: "", logos: [])
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        signIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData {
            if self.favoriteTeam == nil {
                self.favoriteTeam = Team(id: 0, school: "", mascot: "", abbreviation: "", color: "", alt_color: "", logos: [])
            }
        }
        games.getData(teamName: favoriteTeam.school) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.favoriteTeam.id == 0 {
                    self.performSegue(withIdentifier: "ShowTeams", sender: nil)
                    self.tabBarController?.tabBar.items?[0].isEnabled = false
                    self.tabBarController?.tabBar.items?[1].isEnabled = false
                } else {
                    self.tabBarController?.tabBar.items?[0].isEnabled = true
                    self.tabBarController?.tabBar.items?[1].isEnabled = true
                }
            }
        }
        updateUserInterface()
    }
    
    func updateUserInterface() {
        if favoriteTeam == nil || favoriteTeam.id == 0 {
            return
        }
        navigationController?.navigationBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
        tabBarController?.tabBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
        if favoriteTeam.alt_color != nil {
            navigationController?.navigationBar.tintColor = UIColor(hex: "\(favoriteTeam.alt_color!)ff")
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(hex: "\(favoriteTeam.alt_color!)ff"), NSAttributedString.Key.font:UIFont(name: "Avenir Next Condensed Demi Bold", size: 30.0)]
        }
        navigationItem.title = favoriteTeam.school.uppercased()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowGameDetail" {
            let destination = segue.destination as! GameDetailViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.game = games.gameArray[selectedIndexPath.row]
        } else if segue.identifier == "ShowTeams" && favoriteTeam.id != 0 {
            let destination = segue.destination as! TeamListViewController
            destination.selectedTeam = favoriteTeam
        }
    }
    
    @IBAction func unwindFromDetailViewController(segue: UIStoryboardSegue) {
        let source = segue.source as! TeamListViewController
        source.selectedTeam = source.teams.teamArray[source.tableView.indexPathForSelectedRow!.row]
        favoriteTeam = source.teams.teamArray[source.tableView.indexPathForSelectedRow!.row]
        saveData()
        print("New favorite team - the \(favoriteTeam.mascot)!")
        updateUserInterface()
    }
    
    func saveData() { // To save favoriteTeam locally
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentURL = directoryURL.appendingPathComponent("favoriteTeam").appendingPathExtension("json")
        
        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(favoriteTeam)
        do {
            try data?.write(to: documentURL, options: .noFileProtection)
        } catch {
            print("ERROR: Could not save data \(error.localizedDescription)")
        }
    }
    
    func loadData(completed: @escaping () -> ()) {
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentURL = directoryURL.appendingPathComponent("favoriteTeam").appendingPathExtension("json")

        guard let data = try? Data(contentsOf: documentURL) else {return}
        let jsonDecoder = JSONDecoder()
        do {
            favoriteTeam = try jsonDecoder.decode(Team.self, from: data)
        } catch {
            print("ERROR: Could not load data \(error.localizedDescription)")
        }
        completed()
    }
    
    func signIn() {
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
        ]
        if authUI.auth?.currentUser == nil {
            self.authUI?.providers = providers
            let loginViewController = authUI.authViewController()
            loginViewController.modalPresentationStyle = .fullScreen
            present(loginViewController, animated: true, completion: nil)
        } else {
            guard let currentUser = authUI.auth?.currentUser else {
                print("ERROR: couldn't get currentUser")
                return
            }
            let htUser = HTUser(user: currentUser)
            htUser.saveIfNewUser { (success) in
                if success {
                    self.tableView.isHidden = false
                } else {
                    print("ERROR: tried to save a new user but failed")
                }
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    // Created helper function because API date is not in standard format
    func getDate(date: String) -> [String] {
        let dateArray = Array(date)
        let monthDict = ["8": "Aug", "9": "Sep", "10": "Oct", "11": "Nov", "12": "Dec", "1" : "Jan"]
        var amPM: String
        var hour = Int("\(dateArray[11])\(dateArray[12])") ?? 12
        var minute = Int("\(dateArray[14])\(dateArray[15])") ?? 0
        var month = Int("\(dateArray[5])\(dateArray[6])") ?? 8
        var day = Int("\(dateArray[8])\(dateArray[9])") ?? 31
        
        hour -= 5 // For time zone conversion
        if hour <= 0 {
            day -= 1
            hour += 24
        }
        if hour > 12 {
            hour -= 12
            amPM = "PM"
        } else if hour == 12 {
            amPM = "PM"
        } else {
            amPM = "AM"
        }
        
        let monthStr = monthDict["\(month)"] ?? ""
        return [amPM, "\(hour)", "\(minute)", monthStr, "\(day)"]
    }


    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        do {
            try authUI!.signOut()
            tableView.isHidden = true
            signIn()
        } catch {
            tableView.isHidden = true
            print("ERROR: couldn't sign out")
        }
    }
    
    @IBAction func favoriteTeamPressed(_ sender: UIBarButtonItem) {
    }
}

extension GamesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.gameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as! GameTableViewCell
        if games.gameArray[indexPath.row].home_points != nil {
            cell.dateLabel.isHidden = true
            cell.timeLabel.isHidden = true
            cell.homeScoreLabel.text = "\(games.gameArray[indexPath.row].home_points!)"
            cell.awayScoreLabel.text = "\(games.gameArray[indexPath.row].away_points!)"
        } else {
            let date = getDate(date: self.games.gameArray[indexPath.row].start_date)
            cell.homeScoreLabel.text = ""
            cell.awayScoreLabel.text = ""
            cell.dateLabel.isHidden = false
            cell.timeLabel.isHidden = false
            cell.dateLabel.text = date[3] + " " + date[4]
            cell.timeLabel.text = "\(date[1]):\(Int(date[2]) ?? 0 < 10 ? "0\(date[2])" : date[2]) \(date[0])"
        }
        cell.homeNameLabel.text = games.gameArray[indexPath.row].home_team
        cell.awayNameLabel.text = games.gameArray[indexPath.row].away_team
        
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

extension GamesListViewController: FUIAuthDelegate {
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if let user = user {
            // Assumes data will be isplayed in a tableView that was hidden until login was verified so unauthorized users can't see data.
            tableView.isHidden = false
            print("^^^ We signed in with the user \(user.email ?? "unknown e-mail")")
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        let marginInsets: CGFloat = 16.0 // amount to indent UIImageView on each side
        let topSafeArea = self.view.safeAreaInsets.top
        
        // Create an instance of the FirebaseAuth login view controller
        let loginViewController = FUIAuthPickerViewController(authUI: authUI)
        
        // Set background color to white
        loginViewController.view.backgroundColor = UIColor.red
        loginViewController.view.subviews[0].backgroundColor = UIColor.clear
        loginViewController.view.subviews[0].subviews[0].backgroundColor = UIColor.clear
        
        // Create a frame for a UIImageView to hold our logo
        let x = marginInsets
        let y = marginInsets + topSafeArea
        let width = self.view.frame.width - (marginInsets * 2)
        //        let height = loginViewController.view.subviews[0].frame.height - (topSafeArea) - (marginInsets * 2)
        let height = UIScreen.main.bounds.height - (topSafeArea) - (marginInsets * 2)
        
        let logoFrame = CGRect(x: x, y: y, width: width, height: height)
        
        // Create the UIImageView using the frame created above & add the "logo" image
        let logoImageView = UIImageView(frame: logoFrame)
        logoImageView.image = UIImage(named: "logo")
        logoImageView.contentMode = .scaleAspectFit // Set imageView to Aspect Fit
        loginViewController.view.addSubview(logoImageView) // Add ImageView to the login controller's main view
        return loginViewController
    }
}

// To get UIColor from hex value
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
