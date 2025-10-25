//
//  ConversationState.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//

import Foundation
import Combine

final class ConversationState {
    
    private let dispatch: Dispatch
    
    private(set) var conversationListPublisher = PassthroughSubject<[ConversationDataModel], Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(dispatch: @escaping Dispatch, listner: AnyPublisher<ConversationUpdateAction?, Never>) {
        self.dispatch = dispatch
        listner.sink {[weak self] action in
            guard let action else {return}
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    func handle(action: ReduxMutatingAction?) {
        switch action {
            case let action as SetConversationList:
           
            default:
                break
        }
    }
}
