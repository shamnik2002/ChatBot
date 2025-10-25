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
    
    
    func createNewConversation() {
        let id = UUID().uuidString
        let chats = [ChatDataModel]()
        let createConversationAction = CreateConversation(id: id, chats: chats)
        self.appStore.dispacther.dispatch(createConversationAction)
    }
}
