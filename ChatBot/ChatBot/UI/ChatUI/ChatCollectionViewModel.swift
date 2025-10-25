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
    
    init(appStore: AppStore, dataProcessor: any DataProcessor<[ChatDataModel], [ChatCollectionViewDataItem]>) {
        self.appStore = appStore
        self.dataProcessor = dataProcessor
        self.appStore.chatState.responsesPublisher.receive(on: RunLoop.main)
            .sink {[weak self] chatResponses in
                self?.isLoading = false
                self?.processResponse(chatResponses)
            }.store(in: &cancellables)
        
        self.appStore.chatState.userChatMessagePublisher.receive(on: RunLoop.main)
            .sink {[weak self] chatDataModel in
                self?.processUserChatData(chatDataModel)
            }.store(in: &cancellables)
    }
    
    func fetchChats() {
        guard !isLoading else {return}
        isLoading = true
        let getOldChats = GetOldChatResponses()
        self.appStore.dispacther.dispatch(getOldChats)
    }
    
    func fetchOldChats() {
        guard !isLoading else {return}
        isLoading = true
        let getOldChats = GetOldChatResponses()
        self.appStore.dispacther.dispatch(getOldChats)
    }
    
    func processResponse(_ chatResponses:ChatResponses) {
    
        var chats = [ChatDataModel]()
        for response in chatResponses.responses {
            let output = response.output.filter{$0.type == "message"}.first
            guard let output else {continue}
            guard let content = output.content?.first else {continue}
            let outputRole = output.role ?? "assistant"
            let role = ChatResponseRole(rawValue: outputRole) ?? .assistant
            let chat = ChatDataModel(id: output.id , text: content.text, date: response.created_at, type: role)
            chats.append(chat)
        }
        guard !chats.isEmpty else {return}
        
        var chatsUpdateType: ChatsUpdateType = .appended

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
            self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
        }

        internalChatsPublisher.send((self.chatCollectionViewDataItems, chatsUpdateType))
    }
    
    func processUserChatData(_ chatDataModel: ChatDataModel) {
        let lookupData:[ChatCollectionViewDataItem] = [chatCollectionViewDataItems.last(where: {$0 is DateDataModel})].compactMap{$0}
        let chatCollectionViewDataItems = dataProcessor.process(data: [chatDataModel], lookupData: lookupData)
        self.chatCollectionViewDataItems.append(contentsOf: chatCollectionViewDataItems)
        internalChatsPublisher.send((self.chatCollectionViewDataItems, .appended))
    }
}

