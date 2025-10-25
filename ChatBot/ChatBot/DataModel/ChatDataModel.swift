//
//  ChatDataModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//

import Foundation
import Combine

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

nonisolated final class ChatDataModel: ChatCollectionViewDataItem, @unchecked Sendable {
    
    let text: String
    let date: TimeInterval
    let type: ChatResponseRole
    
    init(id: String, text: String, date: TimeInterval, type: ChatResponseRole) {
        self.text = text
        self.date = date
        self.type = type
        super.init(id: id)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

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

nonisolated final class ConversationDataModel: Codable {
    
    let id: String
    let chats:[ChatDataModel]
    
    init(id: String, chats: [ChatDataModel]) {
        self.id = id
        self.chats = chats
    }
}
