//
//  ContentViewModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    private var responses: ChatResponses?
    private var message: String?
    private(set) var appStore: AppStore
    
    init(appStore: AppStore) {
        self.appStore = appStore        
    }
    
    func fetchResponse(input: String) {
        let getResponses = GetChatResponse(input: input)
        self.appStore.dispacther.dispatch(getResponses)
    }
    
    func addText(_ text: String) {
        fetchResponse(input: text)
    }
}
