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
    private var loadingMessage = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Thinking...", "Searching..."], type: .loading)
    private var retryableErrorMessage = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Oops something went wrong"], type: .retryableError, retryableAction: nil)

    init(appStore: AppStore, conversationDataModel: ConversationDataModel, dataProcessor: any DataProcessor<[ChatDataModel], [ChatCollectionViewDataItem]>) {
        self.appStore = appStore
        self.conversationDataModel = conversationDataModel
        self.dataProcessor = dataProcessor
        self.appStore.chatState.responsesPublisher.receive(on: RunLoop.main)
            .sink {[weak self] chatResponse in
                guard conversationDataModel.id == chatResponse.conversationID else {return}
                self?.isLoading = false
                self?.processResponse(chatResponse)
            }.store(in: &cancellables)
        
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
        self.chatCollectionViewDataItems.removeAll { item in
            item.id == loadingMessage.id
        }
        //chatCollectionViewDataItems.append(loadingMessage)
        var message: ChatSystemMessageDataModel?
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
        guard let message else {return}
        self.chatCollectionViewDataItems.append(message)
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
    }
    
    func processResponse(_ chatResponse:ChatResponses) {
    
        guard chatResponse.error == nil else {
            processError(chatResponse)
            return
        }
        let chats = chatResponse.chats
        guard !chats.isEmpty else {return}
        
        var chatsUpdateType: ChatsUpdateType = .appended

        self.chatCollectionViewDataItems.removeAll { item in
            item.id == loadingMessage.id
        }
        
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

        internalChatsPublisher.send((self.chatCollectionViewDataItems, chatsUpdateType))
    }
    
    func processUserChatData(_ chatDataModel: ChatDataModel) {
        
        let lookupData:[ChatCollectionViewDataItem] = [chatCollectionViewDataItems.last(where: {$0 is DateDataModel})].compactMap{$0}
        var chatCollectionViewDataItems = dataProcessor.process(data: [chatDataModel], lookupData: lookupData)
        chatCollectionViewDataItems.append(loadingMessage)
        self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
        isLoading = true
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
    }
    
    func retryAction(_ action: GetChat) {
        print("###### retrying")
        chatCollectionViewDataItems.removeAll { item in
            item.id == retryableErrorMessage.id
        }
        chatCollectionViewDataItems.append(loadingMessage)
        isLoading = true
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
        var newAction = action
        newAction.retryAttempt += 1
        appStore.dispacther.dispatch(newAction)
    }
}

