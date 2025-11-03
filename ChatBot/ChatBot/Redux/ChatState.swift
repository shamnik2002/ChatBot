//
//  State.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

struct ChatResponses {
    var conversationID: String
    var chats: [ChatDataModel]
    var error: ChatError?
}

final class ChatState {
    
    private let dispatch: Dispatch
    
    private(set) var responsesPublisher = PassthroughSubject<ChatResponses, Never>()
    private(set) var userChatMessagePublisher = PassthroughSubject<(String, ChatDataModel), Never>()
    private(set) var errorPublisher = PassthroughSubject<ReduxAction?, Error>()
    private var cancellables = Set<AnyCancellable>()
    
    init(dispatch: @escaping Dispatch, listner: AnyPublisher<SetChat?, Never>) {
        self.dispatch = dispatch
        listner.sink {[weak self] action in
            guard let action else {return}
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    func handle(action: ReduxMutatingAction?) {
        switch action {
            case let action as SetChatResponse:
                let chatresponses = ChatResponses(conversationID: action.conversationID, chats: action.chats, error: action.error)
                responsesPublisher.send(chatresponses)                
            case let action as SetChats:
                let chatresponses = ChatResponses(conversationID: action.conversationID, chats: action.chats, error: action.error)
                responsesPublisher.send(chatresponses)
            case let action as SetUserChatMessage:
                userChatMessagePublisher.send((action.conversationID, action.chatDataModel))
            default:
                break
        }
    }
}
