//
//  UserListViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 1/23/21.
//

import UIKit

class UserListViewController: UIViewController {
    @IBOutlet weak var userTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var userList: [String]!
    var filteredUserList: [String]!
    var htUser: HTUser!
    var originalUser: HTUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userTableView.delegate = self
        userTableView.dataSource = self
        searchBar.delegate = self
        
        filteredUserList = userList
        
        // Hide keyboard if we tap outside of field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowUser" {
            let destination = segue.destination as! ProfileViewController
            destination.originalUser = originalUser
            destination.htUser = originalUser
            destination.userEmail = userList[userTableView.indexPathForSelectedRow!.row]
        }
    }

}

extension UserListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUserList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = userTableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserTableViewCell
        cell.userImageView.layer.cornerRadius = cell.userImageView.frame.size.width / 2
        cell.userImageView.clipsToBounds = true
        cell.userImageView.image = UIImage()
        
        HTUser().getUserForEmail(email: filteredUserList[indexPath.row]) { (user) in
            cell.usernameLabel?.text = user.displayName
            user.loadImage { (success) in
                cell.userImageView.image = success ? user.image : UIImage(systemName: "person.circle")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}

extension UserListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            // When there is no text, filteredData is the same as the original data
            // When user has entered text into the search box
            // Use the filter method to iterate over all items in the data array
            // For each item, return true if the item should be included and false if the
            // item should NOT be included
            filteredUserList = searchText.isEmpty ? userList : userList.filter { (item: String) -> Bool in
                // If dataItem matches the searchText, return true to include it
                return item.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
            }
        if filteredUserList != userList {
            userTableView.reloadData()
        }
    }
}
