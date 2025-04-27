//
//  DatabaseManager.swift
//  ChatApp
//
//  Created by Nishant Kumar on 27/04/25.
//

import Foundation
import FirebaseDatabase

struct User {
    let email: String
    let name: String
}

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    static let databaseURL = "https://chatapp-77bf7-default-rtdb.asia-southeast1.firebasedatabase.app"
    private let database = Database.database(url: databaseURL).reference()
    
    public func insertUser(with user: User) {
        let safeEmail = Utils.getSafeEmail(from: user.email)
        database.child(safeEmail).setValue([
            "name": user.name
        ])
        
        insertIntoAllUsers(with: user)
    }
    
    public func getAllUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let usersArray = snapshot.value as? [[String: String]] else {
                completion(.failure("Failed to load users from database." as! Error))
                return
            }
            
            let users: [User] = usersArray.compactMap { dict in
                guard let name = dict["name"], let email = dict["email"] else {
                    return nil
                }
                return User(email: email, name: name)
            }
            
            completion(.success(users))
        })
    }
    
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message,completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let ref = database.child("\(Utils.getSafeEmail(from: otherUserEmail))")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                print("User not found")
                completion(false)
                return
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let messageDate = firstMessage.sentDate
            let dateString = Utils.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
            case .text(let msgText):
                message = msgText
            default:
                break
            }
            
            let newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "isRead": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversation)
                userNode["conversations"] = conversations
            } else {
                userNode["conversations"] = [
                    newConversation
                ]
            }
            
            ref.setValue(userNode, withCompletionBlock: { error,_ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self.updateConversations(conversationId: conversationId, messageId: firstMessage.messageId, message: message, dateString: dateString, currentUserEmail: currentUserEmail, completion: completion)
            })
        })
    }
    
    private func updateConversations(conversationId: String,
                                     messageId: String,
                                     message: String,
                                     dateString: String,
                                     currentUserEmail: String,
                                     completion: @escaping (Bool) -> Void) {
        let newMessage: [String: Any] = [
            "id": messageId,
            "type": "text",
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        let value: [String: Any] = [
            "messages": [
                newMessage
            ]
        ]
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error,_ in
            guard error == nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    private func insertIntoAllUsers(with user: User) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            if var usersArray = snapshot.value as? [[String: String]] {
                let newUser = [
                    "name": user.name,
                    "email": user.email
                ]
                usersArray.append(newUser)
                
                self.database.child("users").setValue(usersArray)
            } else {
               let newUserArray: [[String: String]] = [[
                    "name": user.name,
                    "email": user.email
                ]]
                self.database.child("users").setValue(newUserArray)
            }
        })
    }
}
