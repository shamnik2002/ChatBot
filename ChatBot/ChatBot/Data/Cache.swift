//
//  Cache.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//

import Foundation
import Combine

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
    
    func setConversation(_ conversation: ConversationDataModel, for conversationID: String){
        removeConversation(conversation)
        addConversation(conversation)
    }
    
    func addConversation(_ conversation: ConversationDataModel) {
        self.conversations.insert(conversation, at: 0)
    }
    
    func removeConversation(_ conversation: ConversationDataModel) {
        self.conversations.removeAll { convo in
            convo.id == conversation.id
        }
    }
    
    func addChatsToConversation(_ chats: [ChatDataModel], conversationID: String) {
        
        self.chats[conversationID, default: []] += chats
    }
    
    func getChats(conversationID: String) -> [ChatDataModel] {
        guard let chatDataModels = self.chats[conversationID] else {return []}
        return chatDataModels.sorted { $0.date < $1.date }
    }
    
}
