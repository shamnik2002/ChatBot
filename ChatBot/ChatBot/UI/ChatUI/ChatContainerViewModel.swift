//
//  ContentViewModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import Foundation
import Combine

final class ChatContainerViewModel: ObservableObject {
    private(set) var appStore: AppStore
    var conversationDataModel: ConversationDataModel
    init(appStore: AppStore, conversationDataModel: ConversationDataModel) {
        self.appStore = appStore
        self.conversationDataModel = conversationDataModel
    }
    
    func fetchResponse(input: String) {
        let getResponses = GetChatResponse(input: input, conversationID: conversationDataModel.id, retryAttempt: 0)
        self.appStore.dispacther.dispatch(getResponses)
    }
    
    func addText(_ text: String) {
        fetchResponse(input: text)
    }
}
