//
//  ChatDataModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//

import Foundation
import Combine

/// ChatCollectionViewDataItem
/// DataModel used by collectionview diffable data source
nonisolated class ChatCollectionViewDataItem: Hashable, @unchecked Sendable, Codable {
    
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    static func == (lhs: ChatCollectionViewDataItem, rhs: ChatCollectionViewDataItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// ChatDataModel
/// Data model used to display chat message (from user or OpenAI API)
nonisolated final class ChatDataModel: ChatCollectionViewDataItem, @unchecked Sendable {
    
    let text: String
    let date: TimeInterval
    let type: ChatResponseRole
    let conversationID: String
    let responseId: String?
    init(id: String, conversationID: String, text: String, date: TimeInterval, type: ChatResponseRole, responseId: String? = nil) {
        self.text = text
        self.date = date
        self.type = type
        self.conversationID = conversationID
        self.responseId = responseId
        super.init(id: id)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

/// DateDataModel
/// Data model used to display the date sections
nonisolated final class DateDataModel: ChatCollectionViewDataItem, @unchecked Sendable {
    let date: TimeInterval
    
    init(id: String, date: TimeInterval) {
        self.date = date
        super.init(id: id)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

/// ChatSystemMessageType
/// defines the different types of system message to display to user in the chat view
enum ChatSystemMessageType {
    case loading
    case error
    case retryableError
}

/// ChatSystemMessageDataModel
/// Displays systems like thinking... when API calls goes out and we are awaiting response
/// shows error like access denied on missing API key
/// Show retryable errors and allows user to repeat the last action
nonisolated final class ChatSystemMessageDataModel: ChatCollectionViewDataItem, @unchecked Sendable {

    let texts: [String]
    let type: ChatSystemMessageType
    var retryableAction: GetChat?
    
    init(id: String, texts: [String], type: ChatSystemMessageType, retryableAction: GetChat? = nil) {
        self.texts = texts
        self.type = type
        self.retryableAction = retryableAction
        super.init(id: id)
    }
    
    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(texts)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

/// ConversationDataModel
/// Data model used to display the conversations in the list
nonisolated final class ConversationDataModel: Codable, Identifiable, Hashable {
    static func == (lhs: ConversationDataModel, rhs: ConversationDataModel) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    var title: String
    var date: TimeInterval
    
    init(id: String, title: String, date: TimeInterval) {
        self.id = id
        self.title = title
        self.date = date
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(date)
    }
}

/// ChatReponsesTransformer
/// Transforms OpenAI response into ChatDataModel
struct ChatReponsesTransformer {
        
    static func chatDataModelFromOpenAIResponses(_ chatResponses: OpenAIResponse, conversationID: String) -> [ChatDataModel] {
        var chats = [ChatDataModel]()
        let output = chatResponses.output.filter{$0.type == "message"}.first
        let responseId = chatResponses.id
        guard let output else {return []}
        guard let content = output.content?.first else {return []}
        let outputRole = output.role ?? "assistant"
        let role = ChatResponseRole(rawValue: outputRole) ?? .assistant
        let chat = ChatDataModel(id: output.id, conversationID: conversationID , text: content.text, date: Date().timeIntervalSince1970, type: role, responseId: responseId)
        chats.append(chat)
        
        return chats
    }
}
