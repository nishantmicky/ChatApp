//
//  ConversationViewController.swift
//  ChatApp
//
//  Created by Nishant Kumar on 27/04/25.
//

import Foundation
import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

class ConversationViewController: MessagesViewController {
    var currentUserEmail: String
    var otherUserEmail: String
    var conversationId: String
    var messages = [Message]()
    
    init(_ currentUserEmail: String, _ otherUserEmail: String) {
        self.currentUserEmail = currentUserEmail
        self.otherUserEmail = otherUserEmail
        self.conversationId = Utils.getConversationId(currentUserEmail, otherUserEmail)
        super.init(nibName: nil, bundle: nil)
        getMessages(self.conversationId)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        self.messagesCollectionView.reloadData()
    }
    
    func getMessages(_ id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    self?.messagesCollectionView.scrollToLastItem()
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        })
    }
}

extension ConversationViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var currentSender: SenderType {
        var currentEmail = ""
        var currentName = ""
        if let email = UserDefaults.standard.object(forKey: "email") as? String {
            currentEmail = email
        }
        if let name = UserDefaults.standard.object(forKey: "name") as? String {
            currentName = name
        }
        return Sender(senderId: currentEmail, displayName: currentName)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        let sender = message.sender
        let components = sender.displayName.components(separatedBy: " ")
        var initials = ""

        if let first = components.first?.first {
            initials.append(first)
        }
        if components.count > 1, let last = components.last?.first {
            initials.append(last)
        }

        let avatar = Avatar(initials: initials.uppercased())
        avatarView.set(avatar: avatar)
    }
}

extension ConversationViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        let messageId = Utils.getConversationId(currentUserEmail, otherUserEmail)
        let message = Message(sender: currentSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User",firstMessage: message, completion: { success in
            if success {
                inputBar.inputTextView.text = ""
                print("Message sent")
            } else {
                print("Failed to sent message")
            }
        })
    }
}
