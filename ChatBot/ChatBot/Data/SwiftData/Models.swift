//
//  Models.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/1/25.
//
import Foundation
import SwiftData
// NOTE: we are intentionally keeping a flattened data store to reduce relationships complexity
// Instead we rely on our cache and middleware to appropriately fetch necessary data

/// ConversationModel
/// Swift data model to store conversation data
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

/// ChatMessageModel
/// Swift data model to store chat message
/// It keeps a reference to the conversation using conversationID
@Model
final class ChatMessageModel {
    @Attribute(.unique) var id: String
    var conversationID: String
    var text: String
    var date: TimeInterval
    var role: String // currently handling assisstant or user
    var responseId: String? // OpenAI responses API responseID to provide context in future requests
    var modelId: String
    var modelProviderId: String
    
    init(id: String, conversationID: String, text: String, date: TimeInterval, role: ChatResponseRole, responseId: String? = nil, modelId: String = OpenAIProvider.OpenAIModels.gpt_5_nano.rawValue, modelProviderId: String = OpenAIProvider.id) {
        self.id = id
        self.conversationID = conversationID
        self.text = text
        self.date = date
        self.role = role.rawValue
        self.responseId = responseId
        self.modelId = modelId
        self.modelProviderId = modelProviderId
    }
}

/// UsageModel
/// Swift data model to store token usage data
/// It keeps reference to both chat and conversation using their IDs
@Model
final class UsageModel {
    @Attribute(.unique) var id: String
    var conversationID: String
    var chatMessageID: String
    var inputTokens: Int
    var outputTokens: Int
    var date: TimeInterval
    var duration: Int
    
    init(id: String, conversationID: String, chatMessageID: String, inputTokens: Int, outputTokens: Int, date: TimeInterval, duration: Int) {
        self.id = id
        self.conversationID = conversationID
        self.chatMessageID = chatMessageID
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.date = date
        self.duration = duration
    }
}
