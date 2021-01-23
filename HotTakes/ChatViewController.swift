//
//  ChatViewController.swift
//  HotTakes
//
//  Created by Zach Crews on 12/3/20.
//

import UIKit
import Firebase

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d, h:mm a"
    return dateFormatter
}()

class ChatViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    var messages: Messages!
    var favoriteTeam: Team!
    var imagePickerController = UIImagePickerController()
    var imageMessage: Message!
    var htUser: HTUser!
    
    var originalKeyboardY: CGFloat!
    var newKeyboardY: CGFloat!
    var keyboardHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages = Messages()
        
        // Hide keyboard if we tap outside of field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        imagePickerController.delegate = self
        
        messages.loadData {
            DispatchQueue.main.async {
                self.tableView.isHidden = self.messages.messageArray.count == 0
                self.messages.messageArray.sort {
                    $0.sentOn > $1.sentOn
                }
                self.tableView.reloadData()
                if self.messages.messageArray.count > 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                }
            }
        }
        
        originalKeyboardY = messageTextField.frame.origin.y
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.favoriteTeam == nil {
            self.favoriteTeam = Team(id: 0, school: "", mascot: "", abbreviation: "", color: "", alt_color: "", logos: [])
        }
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "\(favoriteTeam.alt_color ?? "")ff")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if messages.messageArray.count != 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowProfile" {
            print("running ShowProfile")
            let destination = segue.destination as! ProfileViewController
            destination.userEmail = messages.messageArray[tableView.indexPathForSelectedRow?.row ?? 0].postingUserID
            destination.htUser = htUser
        }
//        if segue.identifier == "ShowPhoto" {
//            let destination = segue.destination as! ImageViewController
//            let selectedIndexPath = tableView.indexPathForSelectedRow!
//            destination.image = messages.messageArray[selectedIndexPath.row].image
//        }
    }
    
    @IBAction func sendKeyPressed(_ sender: UITextField) {
        messageTextField.resignFirstResponder()
        messageTextField.frame.origin.y = originalKeyboardY
        let message = Message(body: messageTextField.text!, sentOn: Date(), messageDisplayName: htUser.displayName ?? "", favoriteTeamID: favoriteTeam.id, image: UIImage(), imageURL: "", postingUserID: htUser.email, documentID: "")
        messageTextField.text = ""
        message.saveData { (success) in
            if success {
                print("Message sent successfully!")
                DispatchQueue.main.async {
//                    if !self.messages.messageArray.contains(where: message -> true) {
//                        self.messages.messageArray.append(message)
//                    }
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                }
            }  else {
                print("*** ERROR: couldn't leave this view controller because data wasn't saved.")
            }
        }
    }
    @IBAction func checkTextLength(_ sender: UITextField) {
        if sender.text?.count ?? 0 > 100 {
            sender.text? = String(sender.text?.prefix(100) ?? "")
        }
    }
    
    @IBAction func imageButtonPressed(_ sender: UIBarButtonItem) {
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
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if keyboardHeight != nil && newKeyboardY != nil {
            messageTextField.frame.origin.y = newKeyboardY
            return
        }
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                keyboardHeight = keyboardSize.height
        } else if keyboardHeight == nil {
            keyboardHeight = 0.0
        }
        newKeyboardY = self.view.frame.height - (keyboardHeight * 1.15)
        messageTextField.frame.origin.y = newKeyboardY
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        messageTextField.frame.origin.y = originalKeyboardY
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageMessage = Message(body: "", sentOn: Date(), messageDisplayName: htUser.displayName ?? "", favoriteTeamID: favoriteTeam.id, image: editedImage, imageURL: "", postingUserID: htUser.email, documentID: "")
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageMessage = Message(body: "", sentOn: Date(), messageDisplayName: htUser.displayName ?? "", favoriteTeamID: favoriteTeam.id, image: originalImage, imageURL: "", postingUserID: htUser.email, documentID: "")
        }
        dismiss(animated: true, completion: nil)
        if imageMessage != nil {
            imageMessage.saveDataWithImage { (success) in
                if success {
                    print("Message sent successfully!")
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
                    }
                }  else {
                    print("*** ERROR: couldn't leave this view controller because data wasn't saved.")
                }
            }
        }
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
            self.oneButtonAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.messageArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        if messages.messageArray[indexPath.row].imageURL != "" {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ChatImageTableViewCell
//            cell.postedByLabel.text = messages.messageArray[indexPath.row].messageDisplayName
//            cell.dateLabel.text = dateFormatter.string(from: messages.messageArray[indexPath.row].sentOn)
//            cell.attachedImageView.image = messages.messageArray[indexPath.row].image
//            if self.messages.messageArray[indexPath.row].image.size.width == 0 {
//                messages.messageArray[indexPath.row].loadImage { (success) in
//                    cell.attachedImageView.image = self.messages.messageArray[indexPath.row].image
//                }
//            }
//            guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(messages.messageArray[indexPath.row].favoriteTeamID).png") else {return cell}
//            do {
//                let data = try Data(contentsOf: url)
//                cell.teamImageView?.image = UIImage(data: data)
//            } catch {
//                print("ERROR: error thrown trying to get image from url \(url)")
//            }
//            return cell
//
        //        } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! ChatTableViewCell
        htUser.getUserForEmail(email: messages.messageArray[indexPath.row].postingUserID) { (user) in
            cell.sentByLabel.text = user.displayName
            user.loadImage { (_) in
                cell.profileImageView.image = user.image ?? UIImage()
            }
            guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(user.favoriteTeamID).png") else {return}
            do {
                let data = try Data(contentsOf: url)
                cell.messageImageView?.image = UIImage(data: data)
            } catch {
                print("ERROR: error thrown trying to get image from url \(url)")
            }
        }
        cell.messageLabel.text = messages.messageArray[indexPath.row].body
        cell.dateLabel.text = dateFormatter.string(from: messages.messageArray[indexPath.row].sentOn)
        return cell
        //        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return messages.messageArray[indexPath.row].imageURL == "" ? 100 : 150
    }
}
