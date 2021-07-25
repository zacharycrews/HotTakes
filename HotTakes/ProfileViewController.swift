//
//  ProfileViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/26/20.
//

import UIKit
import Firebase
import FirebaseUI
import GoogleSignIn

class ProfileViewController: UIViewController {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var favoriteTeamImageView: UIImageView!
    @IBOutlet weak var fanForLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    
    var favoriteTeam: Team!
    var htUser: HTUser!
    var originalUser: HTUser!
    var photoData: Data!
    var userEmail: String!
    
//    // For viewing other users' profiles, eliminates load time
//    var favoriteTeamImage: UIImage!
//    var profileImage: UIImage!
    
    var authUI: FUIAuth!
    
    var currentlySigningIn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        
        if self.favoriteTeam == nil {
            self.favoriteTeam = Team()
        }
        
        // round corners of image view
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if userEmail == nil {
            if htUser == nil {
                currentlySigningIn = true
                signIn()
            }
            else if favoriteTeam.id == 0{
                performSegue(withIdentifier: "PresentProfileEdit", sender: nil)
            } else {
                updateUserInterface()
            }
        } else {
            if userEmail! != originalUser.email {
                followButton.isEnabled = true
                followButton.setTitle(originalUser.isFollowing(user: userEmail) ? "Unfollow" : "Follow", for: .normal)
                htUser.getUserForEmail(email: userEmail!) { (user) in
                    self.htUser = user
                    user.loadImage(completion: { (_) in
                        DispatchQueue.main.async {
                            self.updateUserInterface()
                        }
                    })
                }
            } else {
                updateUserInterface()
            }
        }
        
    }
    
    func updateUserInterface() {
        if htUser == nil {return}
        //editProfileButton?.isHidden = (htUser.email != Auth.auth().currentUser?.email)
        nameLabel.text = htUser.displayName
        teamNameLabel?.text = htUser.teamName
        followersButton?.setTitle("\(htUser.followersCount)", for: .normal)
        followingButton?.setTitle("\(htUser.followingCount)", for: .normal)
        updateFanLabel()
        print("Day: \(Date().timeIntervalSince1970 - htUser.userSince.timeIntervalSince1970)")
        
        if favoriteTeam.id != 0 {
            self.navigationController?.navigationBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
            self.navigationController?.navigationBar.tintColor = UIColor(hex: "\(favoriteTeam.alt_color ?? "ffff")ff")
        }
        
        profileImageView.image = htUser.image
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(htUser.favoriteTeamID).png") else {return}
        do {
            photoData = try Data(contentsOf: url)
            favoriteTeamImageView.image = UIImage(data: photoData)
        } catch {
            print("ERROR: error thrown trying to get image from url \(url)")
        }
    }
    
    func updateFanLabel() {
        var str = "Fan for "
        let difference = Date().timeIntervalSince1970 - htUser.userSince.timeIntervalSince1970
        if difference < 3600 {
            fanForLabel.text = "New Fan"
            return
        } else if difference < 86400 {
            let hours = Int(difference/3600)
            str += "\(hours) \(hours == 1 ? "hour" : "hours")"
        } else if difference < 31557600 {
            let days = Int(difference/86400)
            str += "\(days) \(days == 1 ? "day" : "days")"
        } else {
            let years = Int(difference/31557600)
            str += "\(years) \(years == 1 ? "year" : "years")"
        }
        fanForLabel.text = str
    }
    
    func updateOtherTabs() {
                
        guard let chatTab = self.tabBarController?.viewControllers?[1].children[0] as? ChatViewController else {
            return
        }
        guard let scoresTab = self.tabBarController?.viewControllers?[0].children[0] as? GamesListViewController else {
            return
        }
        chatTab.favoriteTeam = favoriteTeam
        chatTab.htUser = htUser
        scoresTab.favoriteTeam = favoriteTeam
        scoresTab.htUser = htUser
        
        for i in 0 ..< (self.tabBarController?.tabBar.items?.count ?? 0) {
            self.tabBarController?.tabBar.items?[i].isEnabled = true
        }
        tabBarController?.tabBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PresentProfileEdit" {
            let destination = segue.destination.children[0] as! EditProfileViewController
            destination.htUser = htUser
            destination.favoriteTeamImage = favoriteTeamImageView.image ?? UIImage()
            destination.selectedProfilePic = profileImageView.image
            if favoriteTeam.id != 0 {
                destination.favoriteTeam = favoriteTeam
            }
        } else if segue.identifier == "ShowFollowers" {
            let destination = segue.destination as! UserListViewController
            destination.userList = htUser.followers
            destination.htUser = htUser
            destination.originalUser = originalUser
        } else if segue.identifier == "ShowFollowing" {
            let destination = segue.destination as! UserListViewController
            destination.userList = htUser.following
            destination.htUser = htUser
            destination.originalUser = originalUser
        }
    }
    
    @IBAction func unwindFromEditProfileViewController(segue: UIStoryboardSegue) {
        let source = segue.source as! EditProfileViewController
        htUser.displayName = source.usernameTextField.text ?? ""
        favoriteTeam = source.selectedTeam
        if htUser.favoriteTeamID != favoriteTeam.id {
            htUser.userSince = Date()
        }
        self.tabBarController?.tabBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
        htUser.favoriteTeamID = favoriteTeam.id
        htUser.teamColorA = favoriteTeam.color
        htUser.teamColorB = favoriteTeam.alt_color ?? ""
        htUser.teamName = favoriteTeam.school
        htUser.image = source.profileImageView.image!
        updateOtherTabs()
        if source.profileImageView.image != UIImage(systemName: "person.circle") {
            htUser.uploadProfilePic(image: source.profileImageView.image!) { (_) in }
        } else {
            htUser.saveUser(true) { (_) in }
        }
    }
    
    func getUserInfo() {
        favoriteTeam.id = htUser.favoriteTeamID
        favoriteTeam.school = htUser.teamName
        favoriteTeam.color = htUser.teamColorA
        favoriteTeam.alt_color = htUser.teamColorB
        
        if favoriteTeam.id == 0 {
            performSegue(withIdentifier: "PresentProfileEdit", sender: nil)
            print("Presenting segue")
        }
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
            htUser = HTUser(user: currentUser) { (_) in
                DispatchQueue.main.async {
                    print("Created user")
                    self.currentlySigningIn = false
                    self.originalUser = self.htUser
                    self.getUserInfo()
                    self.updateUserInterface()
                    self.updateOtherTabs()
                }
            }
        }
    }
    
    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        do {
            try authUI!.signOut()
            htUser = nil
            userEmail = nil
            favoriteTeamImageView.image = UIImage()
            profileImageView.image = UIImage(systemName: "person.circle")
            nameLabel.text = ""
            favoriteTeam = Team(id: 0, school: "", mascot: "", abbreviation: "", color: "", alt_color: "", logos: [])
            signIn()
            navigationController?.navigationBar.barTintColor = UIColor.red
            tabBarController?.tabBar.barTintColor = UIColor.red
            navigationItem.title = ""
        } catch {
            print("ERROR: couldn't sign out")
        }
    }
    
    @IBAction func followButtonPressed(_ sender: UIButton) {
        if originalUser.isFollowing(user: userEmail) { // unfollow them
            originalUser.unfollow(user: userEmail)
            htUser.removeFollower(user: originalUser.email)
            followButton.setTitle("Follow", for: .normal)
        } else { // follow
            originalUser.follow(user: userEmail)
            htUser.addFollower(user: originalUser.email)
            followButton.setTitle("Unfollow", for: .normal)
        }
        updateUserInterface()
        
        // Update user properties for chat tab
        guard let chatTab = self.tabBarController?.viewControllers?[1].children[0] as? ChatViewController else {
            return
        }
        chatTab.htUser = htUser
    }
}


extension ProfileViewController: FUIAuthDelegate {
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
            print("^^^ We signed in with the user \(user.email ?? "unknown e-mail")")
            signIn()
        }
    }
    
    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        let marginInsets: CGFloat = 16.0 // amount to indent UIImageView on each side
        let topSafeArea = self.view.safeAreaInsets.top
        
        // Create an instance of the FirebaseAuth login view controller
        let loginViewController = FUIAuthPickerViewController(authUI: authUI)
        
        // Set background color to red
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
