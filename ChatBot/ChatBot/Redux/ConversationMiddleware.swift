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
    private var chatDataBase: ChatDatabaseActor
    
    init(dispatch: @escaping Dispatch, cache: CBCache, chatDataBase: ChatDatabaseActor, listner: AnyPublisher<ConversationAction?, Never>) {
        self.dispatch = dispatch
        self.cache = cache
        self.chatDataBase = chatDataBase
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
            await chatDataBase.editConversation(conversation)
            // save it to cache
            await cache.setConversation(conversation, for: conversation.id)
            // trigger refresh list action
            fetchConversationList()
        }
    }
    
    /// deleteConversations
    private func deleteConversations(_ conversations: [ConversationDataModel]) {
        Task {
            await chatDataBase.deleteConversations(conversations)
            // delete the convo and chats associated with it from cache
            await cache.removeConversations(conversations)
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
                conversationList = await chatDataBase.getConversations()
                if !conversationList.isEmpty {
                    // update cache
                    await cache.setConversations(conversationList)
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
            await chatDataBase.addConversation(conversation)
        }        
    }
}

