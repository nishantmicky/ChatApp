//
//  DatabaseManager.swift
//  ChatApp
//
//  Created by Nishant Kumar on 27/04/25.
//

import Foundation
import FirebaseDatabase

enum DatabaseError: String, Error {
    case failedToLoadUsers = "Failed to load users from database."
    case failedToLoadConversations = "Failed to load conversations from database."
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
                completion(.failure(DatabaseError.failedToLoadUsers))
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
    
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message,completion: @escaping (Bool) -> Void) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        var currentName = ""
        if let userName = UserDefaults.standard.value(forKey: "name") as? String {
            currentName = userName
        }
        
        let ref = database.child("\(Utils.getSafeEmail(from: currentUserEmail))")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                print("User not found")
                completion(false)
                return
            }
            
            let conversationId = "\(firstMessage.messageId)"
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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let receiver_newConversation: [String: Any] = [
                "id": conversationId,
                "other_user_email": currentUserEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let safeOtherUserEmail = Utils.getSafeEmail(from: otherUserEmail)
            let otherRef = self?.database.child(safeOtherUserEmail)
            otherRef?.observeSingleEvent(of: .value, with: { snapshot in
                var updatedReceiverConversations = [[String: Any]]()
                if let otherUserNode = snapshot.value as? [String: Any],
                   var receiverConversations = otherUserNode["conversations"] as? [[String: Any]] {
                    if let index = receiverConversations.firstIndex(where: {
                        guard let email = $0["other_user_email"] as? String else { return false }
                        return email == currentUserEmail
                    }) {
                        receiverConversations[index]["latest_message"] = [
                            "date": dateString,
                            "message": message,
                            "is_read": false
                        ]
                        updatedReceiverConversations = receiverConversations
                    } else {
                        updatedReceiverConversations = receiverConversations + [receiver_newConversation]
                    }
                } else {
                    updatedReceiverConversations = [receiver_newConversation]
                }
                self?.database.child("\(safeOtherUserEmail)/conversations").setValue(updatedReceiverConversations)
            })

            if var conversations = userNode["conversations"] as? [[String: Any]] {
                if let index = conversations.firstIndex(where: {
                    guard let email = $0["other_user_email"] as? String else { return false }
                    return email == otherUserEmail
                }) {
                    conversations[index]["latest_message"] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                } else {
                    conversations.append(newConversation)
                }
                userNode["conversations"] = conversations
            } else {
                userNode["conversations"] = [newConversation]
            }
            
            ref.setValue(userNode, withCompletionBlock: { error,_ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self?.updateConversations(name: currentName, conversationId: conversationId, messageId: firstMessage.messageId, message: message, dateString: dateString, currentUserEmail: currentUserEmail, completion: completion)
            })
        })
    }
    
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToLoadConversations))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let sent = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: sent, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToLoadConversations))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let messageId = dictionary["id"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
//                      let isRead = dictionary["is_read"] as? Bool,
                      let date = Utils.dateFormatter.date(from: dateString)
                else {
                    return nil
                }
                
                let sender = Sender(senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
            })
            
            completion(.success(messages))
        })
    }
    
    public func getUserName(currentEmail: String, completion: @escaping (String?) -> Void) {
        let ref = database.child("users")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard let usersArray = snapshot.value as? [[String: Any]] else {
                completion(nil)
                return
            }

            for user in usersArray {
                if let email = user["email"] as? String,
                   email == currentEmail,
                   let name = user["name"] as? String {
                    completion(name)
                    return
                }
            }

            completion(nil)
        })
    }
    
    public func updateUserName(currentEmail: String, newName: String) {
        let ref = database.child("users")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var usersArray = snapshot.value as? [[String: Any]] else {
                return
            }
            
            var userFound = false
            for i in 0..<usersArray.count {
                if let email = usersArray[i]["email"] as? String,
                   email == currentEmail {
                    usersArray[i]["name"] = newName
                    userFound = true
                    break
                }
            }

            if userFound {
                ref.setValue(usersArray)
            } else {
                print("User not found in array.")
            }
        })
    }
    
    private func updateConversations(name: String,
                                     conversationId: String,
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
            "name": name,
            "is_read": false
        ]
        database.child("\(conversationId)/messages").observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                conversations.append(newMessage)
                
                self.database.child("\(conversationId)/messages").setValue(conversations, withCompletionBlock: { error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    completion(true)
                })
            } else {
               let newConversationArray: [String: Any] = [
                "messages": [
                    newMessage
                ]
            ]
                self.database.child("\(conversationId)").setValue(newConversationArray, withCompletionBlock: { error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    completion(true)
                })
            }
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
