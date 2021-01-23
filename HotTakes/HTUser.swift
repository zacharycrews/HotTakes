//
//  HTUser.swift
//  HotTakes
//
//  Created by Zach Crews on 12/4/20.
//

import Foundation
import Firebase

class HTUser {
    var email: String
    var displayName: String
    var photoURL: String
    var favoriteTeamID: Int
    var teamName: String
    var teamColorA: String
    var teamColorB: String
    var userSince: Date
    var documentID: String
    
    var image = UIImage()
    
    var dictionary: [String: Any] {
        let timeIntervalDate = userSince.timeIntervalSince1970
        return ["email": email, "displayName": displayName, "photoURL": photoURL, "favoriteTeamID": favoriteTeamID, "teamName": teamName, "teamColorA" : teamColorA, "teamColorB": teamColorB, "userSince": timeIntervalDate]
    }
    
    init(email: String, displayName: String, photoURL: String, favoriteTeamID: Int, teamName: String, teamColorA: String, teamColorB: String, userSince: Date, documentID: String) {
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.favoriteTeamID = favoriteTeamID
        self.teamName = teamName
        self.teamColorA = teamColorA
        self.teamColorB = teamColorB
        self.userSince = userSince
        self.documentID = documentID
    }
    
    convenience init(user: User, completed: @escaping (Bool) -> ()) {
        let email = user.email ?? ""
        let photoURL = ""
        self.init(email: email, displayName: "", photoURL: photoURL, favoriteTeamID: 0, teamName: "", teamColorA: "", teamColorB: "", userSince: Date(), documentID: user.uid)
        let db = Firestore.firestore()
        db.collection("users").document(email).getDocument(completion: { (document, error) in
            if (document?.exists ?? false) {
                self.loadData {
                    completed(true)
                }
            } else {
                self.saveUser(true, completion: {_ in })
                completed(true)
            }
        })
    }
    
    convenience init(dictionary: [String : Any]) {
        let email = dictionary["email"] as! String? ?? ""
        let displayName = dictionary["displayName"] as! String? ?? ""
        let photoURL = dictionary["photoURL"] as! String? ?? ""
        let favoriteTeamID = dictionary["favoriteTeamID"] as! Int? ?? 0
        let teamName = dictionary["teamName"] as! String? ?? ""
        let teamColorA = dictionary["teamColorA"] as! String? ?? ""
        let teamColorB = dictionary["teamColorB"] as! String? ?? ""
        let timeIntervalDate = dictionary["userSince"] as! TimeInterval? ?? TimeInterval()
        let userSince = Date(timeIntervalSince1970: timeIntervalDate)
        self.init(email: email, displayName: displayName, photoURL: photoURL, favoriteTeamID : favoriteTeamID, teamName: teamName, teamColorA: teamColorA, teamColorB: teamColorB, userSince: userSince, documentID: "")
    }
    
    func saveUser(_ wantToOverwrite: Bool, completion: @escaping (Bool)->()) {
        print("SAVING USER DATA***")
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(email)
        userRef.getDocument { (document, error) in
            guard error == nil else {
                print("ERROR: couldn't access document for user \(self.documentID)")
                return completion(false)
            }
//            guard document?.exists == false else {
//                print("Document for user \(self.documentID) already exists")
//                return completion(true)
//            }
            if !wantToOverwrite && self.favoriteTeamID != 0 {
                return completion(true)
            }
            
            // Create the new document
            let dataToSave: [String: Any] = self.dictionary
            db.collection("users").document(self.email).setData(dataToSave) { (error) in
                guard error == nil else {
                    print("ERROR: couldn't save data for \(self.documentID). \(error?.localizedDescription)")
                    return completion(false)
                }
                return completion(true)
            }
        }
    }
    
    func uploadProfilePic(image: UIImage, completion: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // convert photo.image to a Data type so it can be saved in Firebase storage
        guard let photoData = image.jpegData(compressionQuality: 1.0) else {
            print("ERROR: couldn't convert photo.image to Data")
            return
        }
        
        // create metadata so that we can see images in the Firebase Storage console
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        
        // create filename if necessary
        if documentID == "" {
            documentID = email
        }
        
        // create a storage reference to upload this image file to the spot's folder
        let storageRef = storage.reference().child(email)
        
        // create an upload task
        let uploadTask = storageRef.putData(photoData, metadata: uploadMetaData) { (metadata, error) in
            if let error = error {
                print("ERROR: upload for ref \(uploadMetaData) failed. \(error.localizedDescription)")
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            print("Upload to Firebase storage was successful")
            
            storageRef.downloadURL { (url, error) in
                guard error == nil else {
                    print("ERROR: couldn't create a download url \(url)")
                    return completion(false)
                }
                guard let url = url else {
                    print("ERROR: url was nil")
                    return completion(false)
                }
                self.photoURL = "\(url)"
                
                self.saveUser(true) { (_) in
                    completion(true)
                }
            }
            
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("ERROR: upload image task for file \(self.documentID) failed")
            }
        }
        completion(true)
    }
    
    func loadData(completed: @escaping () -> ()) {
        let db = Firestore.firestore()
        db.collection("users").document(self.email ?? "").addSnapshotListener { (querySnapshot, error) in
            guard let document = querySnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                return
            }
            self.favoriteTeamID = data["favoriteTeamID"] as! Int
            self.teamName = data["teamName"] as! String
            self.teamColorA = data["teamColorA"] as! String
            self.teamColorB = data["teamColorB"] as! String
            self.userSince = Date(timeIntervalSince1970: data["userSince"] as! TimeInterval)
            self.displayName = data["displayName"] as! String
            self.photoURL = data["photoURL"] as! String
            self.loadImage(completion: { (_) in
                completed()
            })
        }
    }
    
    func loadImage(completion: @escaping (Bool) -> ()) {
        guard self.email != "" else {
            print("ERROR: no valid image for user \(documentID)")
            return
        }
        let storage = Storage.storage()
        let storageRef = storage.reference().child(email)
        storageRef.getData(maxSize: 25 * 1024 * 1024) { (data,error) in
            if let error = error {
                print("ERROR: an error occurred while reading data from file ref: \(storageRef) error = \(error.localizedDescription)")
                self.image = UIImage(systemName: "person.circle")!
                return completion(false)
            } else {
                self.image = UIImage(data: data!) ?? UIImage(systemName: "person.circle")!
                return completion(true)
            }
        }
    }
    
    func getUserForEmail(email: String, completion: @escaping (HTUser) -> ()) {
        let db = Firestore.firestore()
        var userToReturn = HTUser(email: email, displayName: "Unknown User", photoURL: "", favoriteTeamID: 0, teamName: "", teamColorA: "", teamColorB: "", userSince: Date(), documentID: "")
        db.collection("users").document(email).getDocument(completion: { (document, error) in
            guard let data = document?.data() else {
                print("Document data was empty.")
                completion(userToReturn)
                return
            }
            userToReturn = HTUser(email: email, displayName: data["displayName"] as! String, photoURL: data["photoURL"] as! String, favoriteTeamID: data["favoriteTeamID"] as! Int, teamName: data["teamName"] as! String, teamColorA: data["teamColorA"] as! String, teamColorB: data["teamColorB"] as! String, userSince: Date(timeIntervalSince1970: data["userSince"] as! TimeInterval), documentID: "")
            completion(userToReturn)
        })
    }
}
