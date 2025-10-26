//
//  HomeViewModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//
import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    private(set) var appStore: AppStore
    
    init(appStore: AppStore) {
        self.appStore = appStore
    }
        
    func createNewConversation() -> ConversationDataModel {
        let conversation = ConversationDataModel(id: UUID().uuidString, chats: [])
        let createConversationAction = CreateConversation(conversation: conversation)
        self.appStore.dispacther.dispatch(createConversationAction)
        return conversation
    }
}
