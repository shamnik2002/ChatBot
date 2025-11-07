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
    var currentModel: ProviderModel = OpenAIProvider.model(.gpt_5_nano)
    private var cancellables = Set<AnyCancellable>()

    init(appStore: AppStore, conversationDataModel: ConversationDataModel) {
        self.appStore = appStore
        self.conversationDataModel = conversationDataModel
        self.appStore.settingsState.settingsPublisher
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: {[weak self] value in
                guard let model = value as? ProviderModel else {
                    return
                }
                self?.currentModel = model
            })
            .store(in: &cancellables)
        getCurrentModel()
    }
    
    func getCurrentModel() {
        let action = GetSettingsObject(key: SettingsStore.Constants.currentModelKey)
        appStore.dispacther.dispatch(action)
    }
    ///fetchResponse
    /// Creates and dispatcher the action to fetch response via OpenAi API
    private func fetchResponse(input: String) {
        let getResponses = GetChatResponse(input: input, conversationID: conversationDataModel.id, retryAttempt: 0, model: currentModel)
        self.appStore.dispacther.dispatch(getResponses)
    }
    
    /// addText
    /// Triggered when user submits the text
    func addText(_ text: String) {
        fetchResponse(input: text)
    }
    
    func models() -> [ProviderModel] {
        OpenAIProvider.models()
    }
}
