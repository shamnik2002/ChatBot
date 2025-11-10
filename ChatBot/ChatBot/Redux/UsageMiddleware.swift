//
//  UsageMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/7/25.
//

import Combine
import Foundation

final class UsageMiddleware {
    
    private let dispatch: Dispatch
    private let cache: CBCache
    private let dataStore: ChatDatabaseActor
    private var cancellables = Set<AnyCancellable>()
    
    init(dispatch: @escaping Dispatch, cache: CBCache, dataStore: ChatDatabaseActor, listener: AnyPublisher<UsageAction?, Never>) {
        self.dispatch = dispatch
        self.cache = cache
        self.dataStore = dataStore
        listener.sink {[weak self] action in
            guard let action else {return}
            self?.handle(action)
        }.store(in: &cancellables)
    }
    
    private func handle(_ action: ReduxAction) {
        switch action {
            case let action as GetUsageByChat:
                getUsageByChat(action)
            case let action as GetUsageByConversation:
                getUsageByConversation(action)
            case let action as GetUsageByDate:
                getUsageByDate(action)
            default:
                break
        }
    }
    
    private func getUsageByChat(_ action: GetUsageByChat) {
        Task {
            guard let data = await dataStore.getUsageData(chatMessageId: action.chatMessageId, conversationId: action.conversationId) else {
                return
            }
            let setAction = SetUsage(usageData: [data], originalAction: action)
            dispatch(setAction)
        }
    }
    
    private func getUsageByConversation(_ action: GetUsageByConversation) {
        Task {
            let data = await dataStore.getUsageDataForConversation(action.conversationId)
            let setAction = SetUsage(usageData: data, originalAction: action)
            dispatch(setAction)
        }
    }
    
    private func getUsageByDate(_ action: GetUsageByDate) {
        Task {
            let data = await dataStore.getUsageDataForDate(action.date)
            let setAction = SetUsage(usageData: data, originalAction: action)
            dispatch(setAction)
        }
    }
}
