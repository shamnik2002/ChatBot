//
//  ConversationMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//
import Foundation
import Combine

final class ConversationMiddleware {
    
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    private var cache: CBCache
    init(dispatch: @escaping Dispatch, cache: CBCache, listner: AnyPublisher<ConversationAction?, Never>) {
        self.dispatch = dispatch
        self.cache = cache
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    func handle(action: ReduxAction) {
        switch action {
        case let action as GetConversationList:
            fetchConversationList()
            break
        
        default:
            break
        }
    }
    
    func fetchConversationList() {
        
    }
    
}
