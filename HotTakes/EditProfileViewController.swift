//
//  EditProfileViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 1/2/21.
//

import UIKit

class EditProfileViewController: UIViewController {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var favoriteTeamImageView: UIImageView!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var usernameWarningLabel: UILabel!
    @IBOutlet weak var teamWarningLabel: UILabel!
    
    var favoriteTeam: Team!
    var selectedTeam: Team!
    var favoriteTeamImage: UIImage!
    var selectedProfilePic: UIImage!
    var htUser: HTUser!
    
    var imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if favoriteTeam != nil {
            selectedTeam = favoriteTeam
        }
        usernameTextField.text = htUser?.displayName ?? ""
        profileImageView.image = selectedProfilePic ?? UIImage(systemName: "person.circle")
        
        // round corners of image view
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        imagePickerController.delegate = self
        
        // Hide keyboard if we tap outside of field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUserInterface()
        
        profileIsComplete()
    }
    
    func updateUserInterface() {
        navigationItem.title = "EDIT PROFILE"
        
        favoriteTeamImageView.image = favoriteTeamImage ?? UIImage()
        profileImageView.image = selectedProfilePic
        
        if selectedTeam == nil {
            return
        }
        
        navigationController?.navigationBar.barTintColor = UIColor(hex: "\(selectedTeam.color)ff")
        navigationController?.navigationBar.tintColor = UIColor(hex: "\(selectedTeam.alt_color ?? "")ff")
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor(hex: "\(selectedTeam.alt_color ?? "")ff"), NSAttributedString.Key.font:UIFont(name: "Avenir Next Condensed Demi Bold", size: 26.0)]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTeamsFromProfile" {
            let destination = segue.destination as! TeamListViewController
            destination.selectedTeam = selectedTeam
        }
    }
    
    @IBAction func unwindFromTeamListViewController(segue: UIStoryboardSegue) {
        let source = segue.source as! TeamListViewController
        source.selectedTeam = source.teams.teamArray[source.tableView.indexPathForSelectedRow!.row]
        selectedTeam = source.teams.teamArray[source.tableView.indexPathForSelectedRow!.row]
        guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(selectedTeam.id).png") else {return}
        do {
            let data = try Data(contentsOf: url)
            favoriteTeamImage = UIImage(data: data)
        } catch {
            print("ERROR: error thrown trying to get image from url \(url)")
        }
        profileIsComplete()
        updateUserInterface()

    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        selectedTeam = favoriteTeam
        updateUserInterface()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectTeamButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowTeamsFromProfile", sender: nil)
    }
    
    @IBAction func selectImageButtonTapped(_ sender: UIButton) {
        presentImageOptions()
    }
    
    @IBAction func profilePictureTapped(_ sender: UITapGestureRecognizer) {
        presentImageOptions()
    }
    
    func presentImageOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (_) in
            self.accessPhotoLibrary()
        }
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) in
            self.accessCamera()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func usernameChanged(_ sender: UITextField) {
        profileIsComplete()
    }
    
    func profileIsComplete() {
        let teamSelected = selectedTeam != nil
        let usernameIsValid = usernameTextField.text?.count ?? 0 >= 3
        doneBarButton.isEnabled = teamSelected && usernameIsValid
        cancelBarButton.isEnabled = htUser.favoriteTeamID != 0
        usernameWarningLabel.text = usernameIsValid ? "" : "Username must be at least 3 characters long"
        teamWarningLabel.text = teamSelected ? "" : "Must select favorite team"
    }
    
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedProfilePic = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedProfilePic = originalImage
        }
        updateUserInterface()
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessPhotoLibrary() {
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            present(imagePickerController, animated: true, completion: nil)
        } else {
            oneButtonAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}
