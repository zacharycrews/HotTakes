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
                self.messages.messageArray.sort {
                    $0.sentOn < $1.sentOn
                }
                self.tableView.reloadData()
                if self.messages.messageArray.count > 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: self.messages.messageArray.count - 1, section: 0), at: .bottom, animated: false)
                }
            }
        }
        
        originalKeyboardY = messageTextField.frame.origin.y
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadData {
            if self.favoriteTeam == nil {
                self.favoriteTeam = Team(id: 0, school: "", mascot: "", abbreviation: "", color: "", alt_color: "", logos: [])
            }
        }
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "\(favoriteTeam.color)ff")
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "\(favoriteTeam.alt_color ?? "")ff")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if messages.messageArray.count != 0 {
            self.tableView.scrollToRow(at: IndexPath(row: self.messages.messageArray.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPhoto" {
            let destination = segue.destination as! ImageViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.image = messages.messageArray[selectedIndexPath.row].image
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
    
    @IBAction func sendKeyPressed(_ sender: UITextField) {
        messageTextField.resignFirstResponder()
        messageTextField.frame.origin.y = originalKeyboardY
        let message = Message(body: messageTextField.text!, sentOn: Date(), messageDisplayName: Auth.auth().currentUser?.displayName ?? "", favoriteTeamID: favoriteTeam.id, image: UIImage(), imageURL: "", postingUserID: "", documentID: "")
        messageTextField.text = ""
        message.saveData { (success) in
            if success {
                print("Message sent successfully!")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(at: IndexPath(row: self.messages.messageArray.count - 1, section: 0), at: .bottom, animated: true)
                }
            }  else {
                print("*** ERROR: couldn't leave this view controller because data wasn't saved.")
            }
        }
    }
    
//    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
//        if let selectedIndexPath = tableView.indexPathForSelectedRow {
//            performSegue(withIdentifier: <#T##String#>, sender: <#T##Any?#>)
//        }
//    }
    
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
            imageMessage = Message(body: "", sentOn: Date(), messageDisplayName: Auth.auth().currentUser?.displayName ?? "", favoriteTeamID: favoriteTeam.id, image: editedImage, imageURL: "", postingUserID: "", documentID: "")
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageMessage = Message(body: "", sentOn: Date(), messageDisplayName: Auth.auth().currentUser?.displayName ?? "", favoriteTeamID: favoriteTeam.id, image: originalImage, imageURL: "", postingUserID: "", documentID: "")
        }
        dismiss(animated: true, completion: nil)
        if imageMessage != nil {
            imageMessage.saveDataWithImage { (success) in
                if success {
                    print("Message sent successfully!")
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(at: IndexPath(row: self.messages.messageArray.count - 1, section: 0), at: .bottom, animated: true)
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
        
        if messages.messageArray[indexPath.row].imageURL != "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath) as! ChatImageTableViewCell
            cell.postedByLabel.text = messages.messageArray[indexPath.row].messageDisplayName
            cell.dateLabel.text = dateFormatter.string(from: messages.messageArray[indexPath.row].sentOn)
            cell.attachedImageView.image = messages.messageArray[indexPath.row].image
            if self.messages.messageArray[indexPath.row].image.size.width == 0 {
                messages.messageArray[indexPath.row].loadImage { (success) in
                    cell.attachedImageView.image = self.messages.messageArray[indexPath.row].image
                }
            }
            guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(messages.messageArray[indexPath.row].favoriteTeamID).png") else {return cell}
            do {
                let data = try Data(contentsOf: url)
                cell.teamImageView?.image = UIImage(data: data)
            } catch {
                print("ERROR: error thrown trying to get image from url \(url)")
            }
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! ChatTableViewCell
            cell.messageLabel.text = messages.messageArray[indexPath.row].body
            cell.sentByLabel.text = messages.messageArray[indexPath.row].messageDisplayName
            cell.dateLabel.text = dateFormatter.string(from: messages.messageArray[indexPath.row].sentOn)
            guard let url = URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(messages.messageArray[indexPath.row].favoriteTeamID).png") else {return cell}
            do {
                let data = try Data(contentsOf: url)
                cell.messageImageView?.image = UIImage(data: data)
            } catch {
                print("ERROR: error thrown trying to get image from url \(url)")
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return messages.messageArray[indexPath.row].imageURL == "" ? 100 : 150
    }
}
