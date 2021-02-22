//
//  Message.swift
//  HotTakes
//
//  Created by Zach Crews on 12/3/20.
//

import Foundation
import Firebase

class Message: Equatable {
    var body: String
    var sentOn: Date
    var messageDisplayName: String
    var favoriteTeamID: Int
    var image: UIImage
    var imageURL: String
    var postingUserID: String
    var documentID: String
    
    var sendingUser: HTUser!
    
    var dictionary: [String: Any] {
        let timeIntervalDate = sentOn.timeIntervalSince1970
        return ["body": body, "sentOn": timeIntervalDate, "messageDisplayName": messageDisplayName, "favoriteTeamID": favoriteTeamID, "imageURL": imageURL, "postingUserID": postingUserID, "documentID": documentID]
    }
    
    init(body: String, sentOn: Date, messageDisplayName: String, favoriteTeamID: Int, image: UIImage, imageURL: String, postingUserID: String, documentID: String) {
        self.body = body
        self.sentOn = sentOn
        self.messageDisplayName = messageDisplayName
        self.favoriteTeamID = favoriteTeamID
        self.image = image
        self.imageURL = imageURL
        self.postingUserID = postingUserID
        self.documentID = documentID
    }
    
    convenience init(dictionary: [String: Any]) {
        let body = dictionary["body"] as! String? ?? ""
        let timeIntervalDate = dictionary["sentOn"] as! TimeInterval? ?? TimeInterval()
        let sentOn = Date(timeIntervalSince1970: timeIntervalDate)
        let messageDisplayName = dictionary["messageDisplayName"] as! String? ?? ""
        let favoriteTeamID = dictionary["favoriteTeamID"] as! Int? ?? 0
        let imageURL = dictionary["imageURL"] as! String? ?? ""
        let postingUserID = dictionary["postingUserID"] as! String? ?? ""
        self.init(body: body, sentOn: sentOn, messageDisplayName: messageDisplayName, favoriteTeamID: favoriteTeamID, image: UIImage(), imageURL: imageURL, postingUserID: postingUserID, documentID: "")
    }
    
    convenience init() {
        self.init(body: "", sentOn: Date(), messageDisplayName: "", favoriteTeamID: 0, image: UIImage(), imageURL: "", postingUserID: "", documentID: "")
    }
    
    func saveData(completion: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        // Grab the user ID
        guard let postingUserID = Auth.auth().currentUser?.email else {
            print("ERROR: Could not save data because we don't have a valid postingUserID.")
            return completion(false)
        }
        self.postingUserID = postingUserID
        // create the dictionary representing data we want to save
        let dataToSave: [String : Any] = self.dictionary
        // if we HAVE saved a record, we'll have an ID, otherwise .addDocument will create one.
        if self.documentID == "" { // create a new document via .addDocument
            var ref: DocumentReference? = nil // Firestore will create a new ID for us
            ref = db.collection("messages").addDocument(data: dataToSave) { (error) in
                guard error == nil else {
                    print("ERROR: adding document \(error!.localizedDescription)")
                    return completion(false)
                }
                self.documentID = ref!.documentID
                print("Added document: \(self.documentID)")
                completion(true)
            }
        } else { // else save to the existing documentID
            let ref = db.collection("messages").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                guard error == nil else {
                    print("ERROR: updating document \(error!.localizedDescription)")
                    return completion(false)
                }
                print("Updated document: \(self.documentID)")
                completion(true)
            }
        }
    }
    
    func saveDataWithImage(completion: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // convert photo.image to a Data type so it can be saved in Firebase storage
        guard let photoData = self.image.jpegData(compressionQuality: 0.5) else {
            print("ERROR: couldn't convert photo.image to Data")
            return
        }
        
        // create metadata so that we can see images in the Firebase Storage console
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        
        // create filename if necessary
        if documentID == "" {
            documentID = UUID().uuidString
        }
        
        // create a storage reference to upload this image file to the spot's folder
        let storageRef = storage.reference().child(documentID)
        
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
                self.imageURL = "\(url)"
                
                // create the dictionary representing data we want to save
                let dataToSave: [String : Any] = self.dictionary
                let ref = db.collection("messages").document(self.documentID)
                ref.setData(dataToSave) { (error) in
                    guard error == nil else {
                        print("ERROR: updating document \(error!.localizedDescription)")
                        return completion(false)
                    }
                    print("Updated document: \(self.documentID)")
                    completion(true)
                }
            }
            
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("ERROR: upload image task for file \(self.documentID) failed")
            }
            completion(false)
        }
    }
    
    func loadImage(completion: @escaping (Bool) -> ()) {
        guard self.documentID != "" else {
            print("ERROR: no valid image for message documentID: \(documentID)")
            return
        }
        let storage = Storage.storage()
        let storageRef = storage.reference().child(documentID)
        storageRef.getData(maxSize: 25 * 1024 * 1024) { (data,error) in
            if let error = error {
                print("ERROR: an error occurred while reading data from file ref: \(storageRef) error = \(error.localizedDescription)")
                return completion(false)
            } else {
                self.image = UIImage(data: data!) ?? UIImage()
                return completion(true)
            }
        }
    }
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.sentOn == rhs.sentOn && lhs.postingUserID == rhs.postingUserID
    }
}
