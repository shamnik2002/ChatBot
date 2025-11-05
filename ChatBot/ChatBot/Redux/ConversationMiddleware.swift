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
        // Listner to Get conversation actions from dispatcher
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    /// Handle actions
    private func handle(action: ReduxAction) {
        switch action {
        case _ as GetConversationList:
            fetchConversationList()
            break
        case let action as CreateConversation:
            createConversation(action.conversation)
            break
        case let action as DeleteConversations:
            deleteConversations(action.conversations)
        case let action as EditConversation:
            editConversation(action.conversation)
        default:
            break
        }
    }
    
    /// editConversation
    /// Allow users to rename conversation title
    private func editConversation(_ conversation: ConversationDataModel) {
        Task {
            let convoId = conversation.id
            let convoDescriptor = FetchDescriptor<ConversationModel>(
                predicate: #Predicate{$0.id == convoId}
            )
            // grab the conversation
            if let convoModel = try? modelContext.fetch(convoDescriptor).first {
                // update both title and date so it can be sorted by recency in the list
                convoModel.title = conversation.title
                convoModel.date = conversation.date
                modelContext.insert(convoModel)
            }
            // save it to store
            do {
                try modelContext.save()
            }catch {
                print(error.localizedDescription)
            }
            // save it to cache
            await cache.setConversation(conversation, for: convoId)
            // trigger refresh list action
            fetchConversationList()
        }
    }
    
    /// deleteConversations
    private func deleteConversations(_ conversations: [ConversationDataModel]) {
        Task {            
            conversations.forEach { item in
                let convoId = item.id
                let convoDescriptor = FetchDescriptor<ConversationModel>(
                    predicate: #Predicate{$0.id == convoId}
                )
                // fetch the convo
                let chatDescriptor = FetchDescriptor<ChatMessageModel>(
                    predicate: #Predicate{$0.conversationID == convoId}
                )
                // delete chats associated with convo from store
                if let chats = try? modelContext.fetch(chatDescriptor) {
                    _ = chats.map{modelContext.delete($0)}
                }
                // delete the convo
                if let convoModels = try? modelContext.fetch(convoDescriptor) {
                    convoModels.forEach{
                        modelContext.delete($0)
                    }                    
                }
            }
            // delete the convo and chats associated with it from cache
            await cache.removeConversations(conversations)
            do {
                try modelContext.save()
            }catch {
                // ideally log errors
                print(error.localizedDescription)
            }
            // trigger refresh convo list
            fetchConversationList()
        }
    }
    
    /// fetchConversationList
    private func fetchConversationList() {
        Task {
            // check if available in cache
            var conversationList = await cache.getConversations()
            
            if conversationList.isEmpty {
                // check if we have it in store
                let descriptor = FetchDescriptor<ConversationModel>(
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                if let data = try? modelContext.fetch(descriptor) {
                    conversationList = data.map{ConversationDataModel(id: $0.id, title: $0.title, date: $0.date)}
                    if !conversationList.isEmpty {
                        // update cache
                        await cache.setConversations(conversationList)
                    }
                }
            }
            // Tell state to publish data
            let conversationUpdateAction = SetConversationList(conversationlist: conversationList)
            dispatch(conversationUpdateAction)
        }
    }
    
    /// createConversation
    func createConversation(_ conversation: ConversationDataModel) {
        Task {
            // add to cache
            await cache.addConversation(conversation)
            // trigger convo list refresh
            fetchConversationList()
            Task {@MainActor in
                // save to store
                let convoModel = ConversationModel(id: conversation.id, title: conversation.title, date: Date().timeIntervalSince1970)
                modelContext.insert(convoModel)
                do {
                    try modelContext.save()
                }catch {
                    print(error.localizedDescription)
                }
            }
        }        
    }
}

