//
//  Store.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine
import SwiftData
/// AppStore
/// Does all the work to connect all systems like state, middleware, dispatcher
/// Currently creates all store, network objects.
// TODO: eventually should accept these objects if we want to write tests
final class AppStore {
    
    // Handle publishing chats to UI view models
    let chatState: ChatState
    // Handles fetching chats from cache, store or remote and updating the cache/store as needed
    let chatMiddleWare: ChatMiddleware
    // Handle publishing conversations to UI view models
    let conversationState: ConversationState
    // Handles fetching conversations from cache, store or remote and updating the cache/store as needed
    let conversationMiddleware: ConversationMiddleware
    // Cache for chats and conversation (in memory)
    let cache: CBCache
    // Handles dispatching actions to appropriate handlers
    let dispacther: Dispatcher
    // Hold feature flags
    let featureConfig: FeatureConfig
    // Model context for Swift Data (currently holds chat and conversation models)
    let modelContainer: ModelContainer
    // Actor for database ops
    let chatDatabase: ChatDatabaseActor
    
    init(modelContainer: ModelContainer) {
        self.dispacther = Dispatcher()
        self.cache = CBCache()
        self.featureConfig = FeatureConfig()
        self.modelContainer = modelContainer
        self.chatDatabase = ChatDatabaseActor(modelContainer: modelContainer)
        
        self.chatState = ChatState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$setChat.eraseToAnyPublisher())
        self.chatMiddleWare = ChatMiddleware(dispatch: self.dispacther.dispatch(_:), networkService: NetworkService(), parser: Parser(), cache: self.cache, featureConfig: self.featureConfig, chatDatabase: self.chatDatabase, listner: self.dispacther.$getChat.eraseToAnyPublisher())
        
        self.conversationState = ConversationState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$conversationUpdateAction.eraseToAnyPublisher())
        self.conversationMiddleware = ConversationMiddleware(dispatch: self.dispacther.dispatch(_:), cache: self.cache, chatDataBase: self.chatDatabase, listner: self.dispacther.$conversationAction.eraseToAnyPublisher())
    }
}

