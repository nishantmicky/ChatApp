//
//  Utils.swift
//  ChatApp
//
//  Created by Nishant Kumar on 27/04/25.
//

import Foundation

final class Utils {
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    class public func getSafeEmail(from email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        return safeEmail
    }
    
    class public func getConversationId(_ first: String, _ second: String) -> String {
        let safeOtherUserEmail = Utils.getSafeEmail(from: first)
        let safecurrentUserEmail = Utils.getSafeEmail(from: second)
        let conversationId = "conversation_\(Utils.appendStringsLexicographically(safecurrentUserEmail, safeOtherUserEmail))"
        return conversationId
    }
    
    class private func appendStringsLexicographically(_ first: String, _ second: String) -> String {
        return first < second ? "\(first)_\(second)" : "\(second)_\(first)"
    }
}
