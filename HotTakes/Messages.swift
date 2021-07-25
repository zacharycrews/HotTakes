//
//  Messages.swift
//  HotTakes
//
//  Created by Zach Crews on 12/3/20.
//

import Foundation
import Firebase

class Messages {
    var messageArray: [Message] = []
    let db = Firestore.firestore()
    
    func loadData(completed: @escaping () -> ()) {
        db.collection("messages").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.messageArray = [] // clean out existing messageArray since new data will load
            // there are querySnapshot!.documents.count documents in the snapshot
            for document in querySnapshot!.documents {
                let message = Message(dictionary: document.data())
                message.documentID = document.documentID
                message.loadImage { (_) in
                    print("Loaded image!")
                }
                self.messageArray.append(message)
            }
            completed()
        }
    }

    func loadPostsForFavoriteTeam(id: Int, completed: @escaping () -> ()) {
        db.collection("messages").whereField("favoriteTeamID", isEqualTo: id).addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.messageArray = [] // clean out existing messageArray since new data will load
            // there are querySnapshot!.documents.count documents in the snapshot
            for document in querySnapshot!.documents {
                //if !document.documentID.hasPrefix("\(id)-") {return}
                let message = Message(dictionary: document.data())

                print(document.documentID)
                message.documentID = document.documentID
//                message.loadImage { (_) in
//                    print("Loaded image!")
//                }
                self.messageArray.append(message)
            }
            completed()
        }
    }
    
    func loadPostsForFollowing(user: HTUser, completed: @escaping () -> ()) {
        if user.followingCount == 0 {
            return completed()
        }
        db.collection("messages").whereField("postingUserID", in: user.following).addSnapshotListener {
            (querySnapshot, error) in
            guard error == nil else {
                print("ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.messageArray = [] // clean out existing messageArray since new data will load
            // there are querySnapshot!.documents.count documents in the snapshot
            for document in querySnapshot!.documents {
                //if !document.documentID.hasPrefix("\(id)-") {return}
                let message = Message(dictionary: document.data())
                message.documentID = document.documentID
//                message.loadImage { (_) in
//                    print("Loaded image!")
//                }
                self.messageArray.append(message)
            }
            completed()
        }
    }
}
