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
        case let action as GetUsageTotal:
                getUsageTotal(action)
            default:
                break
        }
    }
    
    private func getUsageByChat(_ action: GetUsageByChat) {
        // TODO: get/save to cache
        Task {
            guard let data = await dataStore.getUsageData(chatMessageId: action.chatMessageId, conversationId: action.conversationId) else {
                return
            }
            let setAction = SetUsage(usageData: [data], originalAction: action)
            dispatch(setAction)
        }
    }
    
    private func getUsageByConversation(_ action: GetUsageByConversation) {
        // TODO: get/save to cache
        Task {
            let data = await dataStore.getUsageDataForConversation(action.conversationId, fetchLimit: action.pageLimit, fetchOffset: action.pageOffset)
            let setAction = SetUsage(usageData: data, originalAction: action)
            dispatch(setAction)
        }
    }
    
    private func getUsageByDate(_ action: GetUsageByDate) {
        // TODO: get/save to cache
        Task {
            let data = await dataStore.getUsageDataForDate(action.date, fetchLimit: action.pageLimit, fetchOffset: action.pageOffset)
            let setAction = SetUsage(usageData: data, originalAction: action)
            dispatch(setAction)
        }
    }
    
    private func getUsageTotal(_ action: GetUsageTotal) {
        Task {
            switch action.type {
            case .conversation(let conversationID):
                getUsageTotalByConversation(conversationID, action: action)
                break
            case .date(date: let date):
                getUsageTotalByDate(date, action: action)
                break
            }
        }
    }
    private func getUsageTotalByConversation(_ conversationID: String, action: GetUsageTotal) {
        Task{
            if let usageTotals = await cache.getUsageTotalByConversation(conversationID) {
                let setAction = SetUsageTotal(usageTotal: usageTotals, isFinished: true)
                dispatch(setAction)
                return
            }

            let type: UsageTotalsType = .conversation(conversationID: conversationID)
            var data = [UsageDataModel]()
            var inputTotal = 0
            var outputTotal = 0
            let pageLimit = 10 // TODO: adjust in future based on performance
            var pageOffset = 0
            var isFinished = false
            repeat {
                data = await dataStore.getUsageDataForConversation(conversationID, fetchLimit: pageLimit, fetchOffset: pageOffset)
                let (inputTokens, outTokens) = data.calculateTotals()
                inputTotal += inputTokens
                outputTotal += outTokens
                let usageTotal = UsageTotals(type: type, inputTokensTotal: inputTotal, outputTokensTotal: outputTotal)
                isFinished = data.count < pageLimit
                pageOffset += pageLimit
                let setAction = SetUsageTotal(usageTotal: usageTotal, isFinished: isFinished)
                dispatch(setAction)
            } while (!isFinished)
            let usageTotal = UsageTotals(type: type, inputTokensTotal: inputTotal, outputTokensTotal: outputTotal)
            await cache.setUsageTotalByConversation(usageTotal, conversationID: conversationID)
        }
    }
    
    private func getUsageTotalByDate(_ date: Date, action: GetUsageTotal) {
        Task{
            if let usageTotals = await cache.getUsageTotalByDate(date) {
                let setAction = SetUsageTotal(usageTotal: usageTotals, isFinished: true)
                dispatch(setAction)
                return
            }

            let type: UsageTotalsType = .date(date: date)
            var data = [UsageDataModel]()
            var inputTotal = 0
            var outputTotal = 0
            let pageLimit = 10 // TODO: adjust in future based on performance
            var pageOffset = 0
            var isFinished = false
            repeat {
                data = await dataStore.getUsageDataForDate(date.timeIntervalSince1970, fetchLimit: pageLimit, fetchOffset: pageOffset)
                let (inputTokens, outTokens) = data.calculateTotals()
                inputTotal += inputTokens
                outputTotal += outTokens
                let usageTotal = UsageTotals(type: type, inputTokensTotal: inputTotal, outputTokensTotal: outputTotal)
                isFinished = data.count < pageLimit
                pageOffset += pageLimit
                let setAction = SetUsageTotal(usageTotal: usageTotal, isFinished: isFinished)
                dispatch(setAction)
            } while (!isFinished)
            let usageTotal = UsageTotals(type: type, inputTokensTotal: inputTotal, outputTokensTotal: outputTotal)
            await cache.setUsageTotalByDate(usageTotal, date: date)
        }
    }
}
