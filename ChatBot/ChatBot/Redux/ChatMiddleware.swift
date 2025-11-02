//
//  AppMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine
import SwiftData

final class ChatMiddleware {
    
    private let networkService: NetworkProtocol
    private let parser: ParseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    private let cache: CBCache
    private let featureConfig: FeatureConfig
    private let modelContext: ModelContext
    
    init(dispatch: @escaping Dispatch,
         networkService: NetworkProtocol,
         parser: ParseProtocol,
         cache: CBCache,
         featureConfig: FeatureConfig,
         modelContext: ModelContext,
         listner: AnyPublisher<GetChat?, Never>) {
        
        self.dispatch = dispatch
        self.networkService = networkService
        self.parser = parser
        self.cache = cache
        self.featureConfig = featureConfig
        self.modelContext = modelContext
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    private func handle(action: ReduxAction) {
        switch action {
            case let action as GetChatResponse:
            addUserMessage(input: action.input, conversationID: action.conversationID)
            if featureConfig.enableOpenAIResponsesAPI && !OpenAIContants.API_Secret.isEmpty {
                fetchResponses(input: action.input, conversationID: action.conversationID)
            }else {
                fetchMockResponse(conversationID: action.conversationID)
            }
                break
        case let action as GetChats:
            fetchChats(conversationID: action.conversationID)
            default:
                break
        }
    }
    
    private func fetchResponses(input: String, conversationID: String) {
        let request = ResponsesRequest(input: input)
        let parser = parser
        networkService.fetchDataWithPublisher(request: request)
            .flatMap { data in
                return parser.parse(data: data, type: OpenAIResponse.self)
            }.sink { completion in
                
            } receiveValue: {[weak self] result in
                self?.processChatResponses(result, conversationID: conversationID)
            }.store(in: &cancellables)
    }
    
    private func processChatResponses(_ responses: OpenAIResponse, conversationID: String) {
        Task {
            let chats = ChatReponsesTransformer.chatDataModelFromOpenAIResponses(responses, conversationID: conversationID)
            await cache.addChatsToConversation(chats, conversationID: conversationID)
            let setChatResponse = SetChatResponse(conversationID: conversationID, chats: chats)
            dispatch(setChatResponse)
            let getConversationList = GetConversationList()
            dispatch(getConversationList)
            Task {@MainActor in
                chats.forEach { data in
                    let model = ChatMessageModel(id: data.id, conversationID: conversationID, text: data.text, date: data.date, role: data.type)
                    modelContext.insert(model)
                }
                do {
                    try modelContext.save()
                }catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    private func addUserMessage(input: String, conversationID: String) {
        Task {
            
            let date = Date()
            let timeInterval = ceil(date.timeIntervalSince1970)
            let uuid = UUID().uuidString
            let userChat = ChatDataModel(id: uuid, conversationID: conversationID, text: input, date: timeInterval, type: ChatResponseRole.user)
            await cache.addChatsToConversation([userChat], conversationID: conversationID)
            let convo = await cache.getConversation(for: conversationID)
            if let convo = convo, convo.title.isEmpty {
                convo.title = String(input.prefix(35))
                await cache.setConversation(convo, for: conversationID)
                modelContext.insert(ConversationModel(id: convo.id, title: convo.title, date: convo.date))
            }            
            let chatMsgModel = ChatMessageModel(id: uuid, conversationID: conversationID, text: input, date: timeInterval, role: ChatResponseRole.user)
            modelContext.insert(chatMsgModel)
            do {
                try modelContext.save()
            }catch {
                print(error.localizedDescription)
            }
            let getConversationList = GetConversationList()
            dispatch(getConversationList)
            let setUserChatMessageAction = SetUserChatMessage(conversationID: conversationID, chatDataModel: userChat)
            dispatch(setUserChatMessageAction)
        }
    }
    
    private func fetchChats(conversationID: String) {
        let dispatch = self.dispatch
        Task {
            var chatDataModels = await cache.getChats(conversationID: conversationID)
            if chatDataModels.isEmpty {
                let descriptor = FetchDescriptor<ChatMessageModel>(
                    predicate: #Predicate{$0.conversationID == conversationID},
                    sortBy: [SortDescriptor(\.date, order: .forward)]
                )
                if let chats = try? modelContext.fetch(descriptor), !chats.isEmpty {
                    chatDataModels = chats.map{ChatDataModel(id: $0.id, conversationID: conversationID, text: $0.text, date: $0.date, type: $0.role)}
                    await cache.addChatsToConversation(chatDataModels, conversationID: conversationID)
                }
            }
                        
            let setChatAction = SetChats(conversationID: conversationID, chats: chatDataModels)
            dispatch(setChatAction)
        }
    }
    
    private func fetchMockResponses(conversationID: String) {
        
        Task {[weak self] in
            let oldChatsText = randomStringGenerator(count: 20)
            var chats = [ChatDataModel]()
            var delta:TimeInterval = 60*2
            for text in oldChatsText {
                let date = mockDate.timeIntervalSince1970 - delta
                chats.append(ChatDataModel(id: UUID().uuidString, conversationID: conversationID, text: text, date: date, type: .assistant))
                delta -= 60*2
            }
            let setResponsesAction = SetChats(conversationID: conversationID, chats: chats)
            self?.dispatch(setResponsesAction)
            mockDate = mockDate.dayBefore
        }
        
    }
    
    private func fetchMockResponse(conversationID: String) {
        Task {[weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let chatBotresponse = randomStringGenerator(count: 1).first else {return}
            let chat = ChatDataModel(id: UUID().uuidString, conversationID: conversationID, text: chatBotresponse, date: Date().timeIntervalSince1970, type: .assistant)
            await self?.cache.addChatsToConversation([chat], conversationID: conversationID)
            let setResponsesAction = SetChatResponse(conversationID: conversationID, chats: [chat])
            self?.dispatch(setResponsesAction)
            Task {@MainActor in
                let model = ChatMessageModel(id: chat.id, conversationID: conversationID,  text: chat.text, date: chat.date, role: chat.type)
                self?.modelContext.insert(model)
                do {
                    try self?.modelContext.save()
                }catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

var mockDate = Date()

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

func randomStringGenerator(count: Int, minStringLength: Int = 500, maxStringLength: Int = 1000) -> [String] {
    var strings = [String]()
    let letters = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    for _ in 0..<count {
        let length = (minStringLength...maxStringLength).randomElement() ?? 5
        let str = String((0..<length).map{ _ in letters.randomElement()! })
        strings.append(str)
    }
    return strings
}
