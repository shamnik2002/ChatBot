//
//  Store.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine
import SwiftData

final class AppStore {
    
    let chatState: ChatState
    let chatMiddleWare: ChatMiddleware
    let conversationState: ConversationState
    let conversationMiddleware: ConversationMiddleware
    let cache: CBCache
    let dispacther: Dispatcher
    let featureConfig: FeatureConfig
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.dispacther = Dispatcher()
        self.cache = CBCache()
        self.featureConfig = FeatureConfig()
        self.modelContext = modelContext
        self.chatState = ChatState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$setChat.eraseToAnyPublisher())
        self.chatMiddleWare = ChatMiddleware(dispatch: self.dispacther.dispatch(_:), networkService: NetworkService(), parser: Parser(), cache: self.cache, featureConfig: self.featureConfig, modelContext: self.modelContext, listner: self.dispacther.$getChat.eraseToAnyPublisher())
        
        self.conversationState = ConversationState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$conversationUpdateAction.eraseToAnyPublisher())
        self.conversationMiddleware = ConversationMiddleware(dispatch: self.dispacther.dispatch(_:), cache: self.cache, modelContext: self.modelContext, listner: self.dispacther.$conversationAction.eraseToAnyPublisher())
    }
}

