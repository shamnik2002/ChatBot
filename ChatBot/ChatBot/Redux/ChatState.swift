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
    // TODO: shamal remove this type, now we use date to decide whether to insert or append
    var responseType: ChatResponseType
}

enum ChatResponseType {
    case new
    case old
}

final class ChatState {
    
    private let dispatch: Dispatch
    
    private(set) var responsesPublisher = PassthroughSubject<ChatResponses, Never>()
    private(set) var userChatMessagePublisher = PassthroughSubject<(String, ChatDataModel), Never>()
    
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
                let chatresponses = ChatResponses(conversationID: action.conversationID, chats: action.chats, responseType: .new)
                responsesPublisher.send(chatresponses)
            case let action as SetOldChatResponses:
                let chatresponses = ChatResponses(conversationID: action.conversationID, chats: action.chats, responseType: .old)
                responsesPublisher.send(chatresponses)
            case let action as SetUserChatMessage:
                userChatMessagePublisher.send((action.conversationID, action.chatDataModel))
            default:
                break
        }
    }
}
