//
//  Models.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/1/25.
//
import Foundation
import SwiftData

@Model
final class ConversationModel {
    @Attribute(.unique) var id: String
    var title: String
    var date: TimeInterval
    
    init(id: String, title: String, date: TimeInterval) {
        self.id = id
        self.title = title
        self.date = date
    }
}

@Model
final class ChatMessageModel {
    @Attribute(.unique) var id: String
    var conversationID: String
    var text: String
    var date: TimeInterval
    var role: String
    var responseId: String?
    
    init(id: String, conversationID: String, text: String, date: TimeInterval, role: ChatResponseRole, responseId: String? = nil) {
        self.id = id
        self.conversationID = conversationID
        self.text = text
        self.date = date
        self.role = role.rawValue
        self.responseId = responseId
    }
}
