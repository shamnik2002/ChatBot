//
//  ConversationMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//
import Foundation
import Combine
import SwiftData

final class ConversationMiddleware {
    
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    private var cache: CBCache
    private var modelContext: ModelContext
    
    init(dispatch: @escaping Dispatch, cache: CBCache, modelContext: ModelContext, listner: AnyPublisher<ConversationAction?, Never>) {
        self.dispatch = dispatch
        self.cache = cache
        self.modelContext = modelContext
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    func handle(action: ReduxAction) {
        switch action {
        case _ as GetConversationList:
            fetchConversationList()
            break
        case let action as CreateConversation:
            createConversation(action.conversation)
            break
        default:
            break
        }
    }
    
    func fetchConversationList() {
        Task {
            var conversationList = await cache.getConversations()
            if conversationList.isEmpty {
                // check if we have it in store
                let descriptor = FetchDescriptor<ConversationModel>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                if let data = try? modelContext.fetch(descriptor) {
                    conversationList = data.map{ConversationDataModel(id: $0.id, title: $0.title, date: $0.date)}
                    if !conversationList.isEmpty {
                        await cache.setConversations(conversationList)
                    }
                }
            }
            
            let conversationUpdateAction = SetConversationList(conversationlist: conversationList)
            dispatch(conversationUpdateAction)
        }
    }
    
    func createConversation(_ conversation: ConversationDataModel) {
        Task {
            await cache.addConversation(conversation)
            fetchConversationList()
            Task {@MainActor in
                let convoModel = ConversationModel(id: conversation.id, title: conversation.title, date: Date().timeIntervalSince1970)
                modelContext.insert(convoModel)
                do {
                    try modelContext.save()
                }catch {
                    print(error)
                }
            }
        }        
    }
}

