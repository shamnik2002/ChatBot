//
//  ConversationState.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//

import Foundation
import Combine
// NOTE: Custom state implementation
// Usually in redux state holds the data, but since we are always publishing/ using declarative approach
// we are not holding the data rather relying o publishers to publish data as soon as available
// In future, if it is needed we can hold data here.

final class ConversationState {
    
    private let dispatch: Dispatch
    
    private(set) var conversationListPublisher = PassthroughSubject<[ConversationDataModel], Never>()
    private(set) var conversationPublisher = PassthroughSubject<ConversationDataModel, Never>()

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
                conversationListPublisher.send(action.conversationlist)
            case let action as SetConversation:
                conversationPublisher.send(action.conversation)
                break
            default:
                break
        }
    }
}
