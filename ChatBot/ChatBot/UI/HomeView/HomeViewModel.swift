//
//  HomeViewModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/25/25.
//
import Foundation
import Combine
import SwiftData

final class HomeViewModel: ObservableObject {
    private(set) var appStore: AppStore
    
    init(modelContext: ModelContext) {
        self.appStore = AppStore(modelContext: modelContext)
    }
        
    func createNewConversation() -> ConversationDataModel {
        let conversation = ConversationDataModel(id: UUID().uuidString, title: "", date: Date().timeIntervalSince1970)
        let createConversationAction = CreateConversation(conversation: conversation)
        self.appStore.dispacther.dispatch(createConversationAction)
        return conversation
    }
}
