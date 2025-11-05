//
//  Cache.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//

import Foundation
import Combine

/// CBCache
/// Single Cache that holds both chat and conversation data
actor CBCache {
    private var conversations: [ConversationDataModel] = []
    private var chats: [String:[ChatDataModel]] = [:]
    
    func getConversations() -> [ConversationDataModel] {
        return conversations
    }
    
    func setConversations(_ conversations:[ConversationDataModel]) {
        self.conversations = conversations
    }
    
    func getConversation(for conversationID: String) -> ConversationDataModel? {
        return self.conversations.first { convo in
            convo.id == conversationID
        }
    }
    
    // replaces exsiting conversation
    func setConversation(_ conversation: ConversationDataModel, for conversationID: String){
        removeConversation(conversation)
        addConversation(conversation)
    }
    
    func addConversation(_ conversation: ConversationDataModel) {
        self.conversations.insert(conversation, at: 0)
    }
    
    /// Removes the associated chats along with the conversation
    func removeConversation(_ conversation: ConversationDataModel) {
        chats[conversation.id] = nil
        self.conversations.removeAll { convo in
            convo.id == conversation.id
        }
    }
    
    /// Removes the associated chats along with the conversations
    func removeConversations(_ conversations: [ConversationDataModel]) {
        conversations.forEach{
            removeConversation($0)
        }
    }
    
    func addChatsToConversation(_ chats: [ChatDataModel], conversationID: String) {
        self.chats[conversationID, default: []] += chats
    }
    
    // Returns chats sorted by date in descending order
    func getChats(conversationID: String) -> [ChatDataModel] {
        guard let chatDataModels = self.chats[conversationID] else {return []}
        return chatDataModels.sorted { $0.date < $1.date }
    }
    
}
