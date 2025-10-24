//
//  State.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

struct ChatResponses {
    var responses: [ChatResponse]
    var responseType: ChatResponseType
}

enum ChatResponseType {
    case new
    case old
}

final class AppState {
    
    private let dispatch: Dispatch
    
    private(set) var responsesPublisher = PassthroughSubject<ChatResponses, Never>()
    private(set) var userChatMessagePublisher = PassthroughSubject<ChatDataModel, Never>()
    
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
                let chatresponses = ChatResponses(responses: [action.response], responseType: .new)
                responsesPublisher.send(chatresponses)
            case let action as SetOldChatResponses:
                let chatresponses = ChatResponses(responses: action.responses, responseType: .old)
                responsesPublisher.send(chatresponses)
            case let action as SetUserChatMessage:
                userChatMessagePublisher.send(action.chatDataModel)            
            default:
                break
        }
    }
}
