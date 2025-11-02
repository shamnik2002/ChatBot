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
    private var systemMessage = ChatSystemMessageDataModel(id: UUID().uuidString, texts: ["Thinking...", "Searching..."])
    
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
    
    func processResponse(_ chatResponse:ChatResponses) {
    
        let chats = chatResponse.chats
        guard !chats.isEmpty else {return}
        
        var chatsUpdateType: ChatsUpdateType = .appended

        self.chatCollectionViewDataItems.removeAll { item in
            item.id == systemMessage.id
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
        chatCollectionViewDataItems.append(systemMessage)
        self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
        isLoading = true
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
    }
}

