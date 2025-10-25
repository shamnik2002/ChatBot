//
//  Store.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

final class AppStore {
    
    let chatState: ChatState
    let chatMiddleWare: ChatMiddleware
    let conversationState: ConversationState
    let conversationMiddleware: ConversationMiddleware
    
    let dispacther: Dispatcher
    static let shared = AppStore()
    
    init() {
        self.dispacther = Dispatcher()
        self.chatState = ChatState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$setChat.eraseToAnyPublisher())
        self.chatMiddleWare = ChatMiddleware(dispatch: self.dispacther.dispatch(_:), networkService: NetworkService(), parser: Parser(), listner: self.dispacther.$getChat.eraseToAnyPublisher())
        
        self.conversationState = ConversationState(dispatch: self.dispacther.dispatch(_:), listner: self.dispacther.$conversationUpdateAction.eraseToAnyPublisher())
        self.conversationMiddleware = ConversationMiddleware(dispatch: self.dispacther.dispatch(_:), cache: CBCache(), listner: self.dispacther.$conversationAction.eraseToAnyPublisher()) 
    }
}

