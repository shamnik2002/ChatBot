//
//  ChatCollectionViewModel.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/17/25.
//

import Foundation
import Combine

protocol ChatCollectionViewModelProtocol {
    func fetchChats()
    var chatsPublisher: AnyPublisher<([ChatCollectionViewDataItem], ChatsUpdateType), Never> {get}
    func retryAction(_ action: GetChat)
}

enum ChatsUpdateType: String {
    case appended
    case inserted
}

final class ChatCollectionViewModel: ChatCollectionViewModelProtocol, ObservableObject {
    
    private var chatCollectionViewDataItems: [ChatCollectionViewDataItem] = []
    var chatsPublisher: AnyPublisher<([ChatCollectionViewDataItem], ChatsUpdateType), Never> {
        internalChatsPublisher.eraseToAnyPublisher()
    }
    private var internalChatsPublisher = PassthroughSubject<([ChatCollectionViewDataItem], ChatsUpdateType), Never>()
    private var cancellables = Set<AnyCancellable>()
    private var appStore: AppStore
    private var isLoading = false
    private var dataProcessor: any DataProcessor<[ChatDataModel], [ChatCollectionViewDataItem]>
    private var conversationDataModel: ConversationDataModel
    // we should always just have a single loading message shown
    private var loadingMessage = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Thinking...", "Searching..."], type: .loading)
    // we should always just have a single retryable error shown
    // Note other non-retryable errors can be multiple if needed
    private var retryableErrorMessage = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Oops something went wrong"], type: .retryableError, retryableAction: nil)

    init(appStore: AppStore, conversationDataModel: ConversationDataModel, dataProcessor: any DataProcessor<[ChatDataModel], [ChatCollectionViewDataItem]>) {
        self.appStore = appStore
        self.conversationDataModel = conversationDataModel
        self.dataProcessor = dataProcessor
        // Listen to responses from OpenAI API
        self.appStore.chatState.responsesPublisher.receive(on: RunLoop.main)
            .sink {[weak self] chatResponse in
                guard conversationDataModel.id == chatResponse.conversationID else {return}
                self?.isLoading = false
                self?.processResponse(chatResponse)
            }.store(in: &cancellables)
        
        // Listen to user inputs
        self.appStore.chatState.userChatMessagePublisher.receive(on: RunLoop.main)
            .sink {[weak self] (convoID, chatDataModel) in
                guard let self else {return}
                guard convoID == self.conversationDataModel.id else {return }
                self.processUserChatData(chatDataModel)
            }.store(in: &cancellables)
    }
    
    func fetchChats() {
        let getChats = GetChats(conversationID: conversationDataModel.id)
        appStore.dispacther.dispatch(getChats)
    }
    
    func fetchOldChats() {
        guard !isLoading else {return}
        isLoading = true
        let getOldChats = GetChats(conversationID: conversationDataModel.id)
        self.appStore.dispacther.dispatch(getOldChats)
    }
    
    func processError(_ chatResponse:ChatResponses) {
        // make sure to rmeove the loading message
        self.chatCollectionViewDataItems.removeAll { item in
            item.id == loadingMessage.id
        }
        var message: ChatSystemMessageDataModel?
        // Check error type and create appropriate message
        guard let error = chatResponse.error else {return}
        switch error.error {
        case .accessDenied:
            message = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Access Denied: Please check your API Key"], type: .error)
        case .retryable:
            message = retryableErrorMessage
            message?.retryableAction = error.originalAction
        case .unknownError:
            message = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Oops something went wrong"], type: .error)
        }
        // insert and trigger UI update
        guard let message else {return}
        self.chatCollectionViewDataItems.append(message)
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
    }
    
    /// processResponse
    /// Process the data we received from chat state
    func processResponse(_ chatResponse:ChatResponses) {
    
        // If we have an error process it
        guard chatResponse.error == nil else {
            processError(chatResponse)
            return
        }
        let chats = chatResponse.chats
        guard !chats.isEmpty else {return}
        
        var chatsUpdateType: ChatsUpdateType = .appended

        // Remove loading message
        self.chatCollectionViewDataItems.removeAll { item in
            item.id == loadingMessage.id
        }
        
        // Based on date decide whether the data we received should be added to the bottom or inserted above
        if !self.chatCollectionViewDataItems.isEmpty {
            // we have some chats
            // check dates to confirm whether to append or insert
            guard let dm = self.chatCollectionViewDataItems.first else {return}
            var date: TimeInterval?
            switch dm {
                case let dm as ChatDataModel:
                    date = dm.date
                case let dm as DateDataModel:
                    date = dm.date
                default:
                    break
            }
            
            guard let date, let newChatsLast = chats.last?.date else {return}
            
            if newChatsLast < date {
                // insert
                let lookupData:[ChatCollectionViewDataItem] = [chatCollectionViewDataItems.first(where: {$0 is DateDataModel})].compactMap{$0}
                let chatCollectionViewDataItems = dataProcessor.process(data: chats, lookupData: lookupData)
                self.chatCollectionViewDataItems.insert(contentsOf: chatCollectionViewDataItems, at: 0)
                chatsUpdateType = .inserted
            }else {
                // append
                let lookupData:[ChatCollectionViewDataItem] = [chatCollectionViewDataItems.last(where: {$0 is DateDataModel})].compactMap{$0}
                let chatCollectionViewDataItems = dataProcessor.process(data: chats, lookupData: lookupData)
                self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
            }
            
        } else {
            // first batch likely
            let chatCollectionViewDataItems = dataProcessor.process(data: chats, lookupData: [])
            self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
        }

        // Trigger UI update
        internalChatsPublisher.send((self.chatCollectionViewDataItems, chatsUpdateType))
    }
    
    /// processUserChatData
    /// Called when we receive user input from Chat state
    func processUserChatData(_ chatDataModel: ChatDataModel) {
        
        // if the date is same we do not want reinsert date data model
        // LookupData helps dedup that
        let lookupData:[ChatCollectionViewDataItem] = [chatCollectionViewDataItems.last(where: {$0 is DateDataModel})].compactMap{$0}
        // Process the data, so we interleave the date in between chat messages
        var chatCollectionViewDataItems = dataProcessor.process(data: [chatDataModel], lookupData: lookupData)
        // add loading message
        chatCollectionViewDataItems.append(loadingMessage)
        self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
        isLoading = true
        // trigger UI update
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
    }

    ///retryAction
    /// Called when user taps on the retry button when they are presented a retryable error
    func retryAction(_ action: GetChat) {
        // remove error message
        chatCollectionViewDataItems.removeAll { item in
            item.id == retryableErrorMessage.id
        }
        // add loading message
        chatCollectionViewDataItems.append(loadingMessage)
        isLoading = true
        // trigger UI update
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
        // dispatch original actor by updating retry attempt
        var newAction = action
        newAction.retryAttempt += 1
        appStore.dispacther.dispatch(newAction)
    }
}

