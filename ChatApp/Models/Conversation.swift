//
//  Conversation.swift
//  ChatApp
//
//  Created by Nishant Kumar on 29/04/25.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
