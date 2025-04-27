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
    var photoURL: String
    var displayName: String
}

class ConversationViewController: MessagesViewController {
    
    var otherUserEmail: String
    var messages = [Message]()
    var selfSender: Sender? = {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        return Sender(senderId: currentUserEmail, photoURL: "", displayName: "")
    }()
    
    init(_ otherUserEmail: String) {
        self.otherUserEmail = otherUserEmail
        super.init(nibName: nil, bundle: nil)
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
    
}

extension ConversationViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var currentSender: SenderType {
        if let sender = selfSender {
            return sender
        }

        return Sender(senderId: "1", photoURL: "", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ConversationViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let sender = selfSender, let messageId = createMessageId() else {
            return
        }
        
        let message = Message(sender: sender, messageId: messageId, sentDate: Date(), kind: .text(text))
        DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: { success in
            if success {
                print("Message sent")
            } else {
                print("Failed to sent message")
            }
        })
    }
    
    private func createMessageId() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let dateString = Utils.dateFormatter.string(from: Date())
        let safeOtherUserEmail = Utils.getSafeEmail(from: otherUserEmail)
        let safecurrentUserEmail = Utils.getSafeEmail(from: currentUserEmail)
        let messageId = "\(safeOtherUserEmail)_\(safecurrentUserEmail)_\(dateString)"
        return messageId
    }
}
