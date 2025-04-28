//
//  Message.swift
//  ChatApp
//
//  Created by Nishant Kumar on 29/04/25.
//

import Foundation
import MessageKit

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
