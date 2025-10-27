//
//  AppMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine

var mockDate = Date()
final class ChatMiddleware {
    
    private let networkService: NetworkProtocol
    private let parser: ParseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    private let cache: CBCache
    private let featureConfig: FeatureConfig
    
    init(dispatch: @escaping Dispatch,
         networkService: NetworkProtocol,
         parser: ParseProtocol,
         cache: CBCache,
         featureConfig: FeatureConfig,
         listner: AnyPublisher<GetChat?, Never>) {
        
        self.dispatch = dispatch
        self.networkService = networkService
        self.parser = parser
        self.cache = cache
        self.featureConfig = featureConfig
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    private func handle(action: ReduxAction) {
        switch action {
            case let action as GetChatResponse:
            addUserMessage(input: action.input, conversationID: action.conversationID)
            if featureConfig.enableOpenAIResponsesAPI {
                fetchResponses(input: action.input, conversationID: action.conversationID)
            }else {
                fetchMockResponse(conversationID: action.conversationID)
            }
                break
        case let action as GetOldChatResponses:
            if !featureConfig.enableOpenAIResponsesAPI {
                fetchMockResponses(conversationID: action.conversationID)
            }
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
            let chats = ChatReponsesTransformer.chatDataModelFromOpenAIResponses(responses)
            await cache.addChatsToConversation(chats, conversationID: conversationID)
            let setChatResponse = SetChatResponse(conversationID: conversationID, chats: chats)
            dispatch(setChatResponse)
            let getConversationList = GetConversationList()
            dispatch(getConversationList)
        }
    }
    
    private func addUserMessage(input: String, conversationID: String) {
        Task {
            let date = ceil(Date().timeIntervalSince1970)
            let userChat = ChatDataModel(id: UUID().uuidString, text: input, date: date, type: ChatResponseRole.user)
            await cache.addChatsToConversation([userChat], conversationID: conversationID)
            let setUserChatMessageAction = SetUserChatMessage(conversationID: conversationID, chatDataModel: userChat)
            dispatch(setUserChatMessageAction)
            let getConversationList = GetConversationList()
            dispatch(getConversationList)
        }
    }
    
    private func fetchMockResponses(conversationID: String) {
        
        Task {[weak self] in
            let oldChatsText = randomStringGenerator(count: 20)
            var chats = [ChatDataModel]()
            var delta:TimeInterval = 60*2
            for text in oldChatsText {
                let date = mockDate.timeIntervalSince1970 - delta
                chats.append(ChatDataModel(id: UUID().uuidString, text: text, date: date, type: .assistant))
                delta -= 60*2
            }
            let setResponsesAction = SetOldChatResponses(conversationID: conversationID, chats: chats)
            self?.dispatch(setResponsesAction)
            mockDate = mockDate.dayBefore
        }
        
    }
    
    private func fetchMockResponse(conversationID: String) {
        Task {[weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let chatBotresponse = randomStringGenerator(count: 1).first else {return}
            let chat = ChatDataModel(id: UUID().uuidString, text: chatBotresponse, date: Date().timeIntervalSince1970, type: .assistant)
            await self?.cache.addChatsToConversation([chat], conversationID: conversationID)
            let setResponsesAction = SetChatResponse(conversationID: conversationID, chats: [chat])
            self?.dispatch(setResponsesAction)
        }
    }
}

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
