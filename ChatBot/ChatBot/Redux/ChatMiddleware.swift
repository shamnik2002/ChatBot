//
//  AppMiddleware.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//

import Foundation
import Combine
import SwiftData

/// ChatErrorType
enum ChatErrorType: String {
    case retryable
    case accessDenied
    case unknownError
}

/// ChatError
/// Holds the original action to allow retrying in case the error is retryable
struct ChatError {
    let error: ChatErrorType
    let originalAction: GetChat
}

/// ChatMiddleware
/// Responsible for fetching/saving  chats from/to  cache/store/remote
final class ChatMiddleware {
    
    private let networkService: NetworkProtocol
    private let parser: ParseProtocol
    private var cancellables = Set<AnyCancellable>()
    private let dispatch: Dispatch
    private let cache: CBCache
    private let featureConfig: FeatureConfig
    private let chatDatabase: ChatDatabaseActor
    private let maxRetryAttempts = 3
    private let serviceProvider: ServiceProvider
    
    init(dispatch: @escaping Dispatch,
         networkService: NetworkProtocol,
         parser: ParseProtocol,
         cache: CBCache,
         featureConfig: FeatureConfig,
         chatDatabase: ChatDatabaseActor,
         listner: AnyPublisher<GetChat?, Never>) {
        
        self.dispatch = dispatch
        self.networkService = networkService
        self.parser = parser
        self.cache = cache
        self.featureConfig = featureConfig
        self.chatDatabase = chatDatabase
        self.serviceProvider = ServiceProvider(networkService: networkService, parser: parser)
        // Listen to any Get chat actions dispatcher sends
        listner.sink {[weak self] action in
            guard let action = action else { return }
            self?.handle(action: action)
        }.store(in: &cancellables)
    }
    
    private func handle(action: ReduxAction) {
        switch action {
            case let action as GetChatResponse:
            // Check if we are retying the request
            if action.retryAttempt <= 0 {
                // we do not want to add user's input chat message again when retrying
                addUserMessage(input: action.input, conversationID: action.conversationID, model: action.model)
            }
            // if feature flag to use OpenAI API is enabled and we have a API key then fetch from remote
            if featureConfig.enableOpenAIResponsesAPI && !OpenAIContants.API_Secret.isEmpty {
                fetchResponses(action: action)
            }else {
                // or just use mock response
                fetchMockResponse(action: action)
            }
                break
        case let action as GetChats:
            // fetch chats from store/cache
            fetchChats(conversationID: action.conversationID)
            default:
                break
        }
    }
    
    /// Fetch responses from OpenAI
    private func fetchResponses(action: GetChatResponse) {
        Task {
            // Create the request and parser
            guard let serviceProvider = serviceProvider.provider(id: action.model.modelProviderId) else {
                //TODO: throw an error here
                return
            }
            var chatDataModel: ChatDataModel?
            if let assisstantChat = await chatDatabase.getLastAssisstantResponseFor(conversationID: action.conversationID) {
                chatDataModel = ChatDataModel(id: assisstantChat.id, conversationID: assisstantChat.conversationID, text: assisstantChat.text, date: assisstantChat.date, type: ChatResponseRole(rawValue: assisstantChat.role) ?? .assistant, responseId: assisstantChat.responseId, modelId: assisstantChat.modelId, modelProviderId: assisstantChat.modelProviderId)
            }
            do {
                let result = try await serviceProvider.fetchResponse(action: action, lastAssisstantChat: chatDataModel)
                self.processChatResponses(result, conversationID: action.conversationID)
            }catch {
                self.processChatError(error, originalAction: action)
            }            
        }
    }
    
    /// processChatError
    /// Sets the appropriate error type and whether we can continue to retry
    private func processChatError(_ error: Error, originalAction: GetChatResponse) {
        var errorType: ChatErrorType = .unknownError
        if originalAction.retryAttempt < maxRetryAttempts {
            switch error {
                case let error as NetworkError:
                    switch error {
                        case .serverError:
                            // retryable
                            errorType = .retryable
                        case .authError, .forbiddenError:
                            // accessDenied
                            errorType = .accessDenied
                        default:
                            break
                    }
                    break
                default:
                    break
            }
        }
                        
        let error = ChatError(error: errorType, originalAction: originalAction)
        let setChatResponse = SetChatResponse(conversationID: originalAction.conversationID, chats: [], error: error)
        dispatch(setChatResponse)
    }
    
    /// processChatResponses
    ///  Processes the response and adds it to cache/store
    private func processChatResponses(_ chats: [ChatDataModel], conversationID: String) {
        Task {
            // save to cache
            await cache.addChatsToConversation(chats, conversationID: conversationID)
            // create action for state to publish
            let setChatResponse = SetChatResponse(conversationID: conversationID, chats: chats, error: nil)
            dispatch(setChatResponse)
            // refresh the conversationList
            // TODO: only do this for new conversations
            let getConversationList = GetConversationList()
            dispatch(getConversationList)
            await chatDatabase.addChats(chats, for: conversationID)
        }
    }
    
    /// addUserMessage
    /// Handles properly saving the user input in cache/store
    private func addUserMessage(input: String, conversationID: String, model: ProviderModelProtocol) {
        Task {
            
            let date = Date()
            let timeInterval = ceil(date.timeIntervalSince1970)
            let uuid = UUID().uuidString
            let userChat = ChatDataModel(id: uuid, conversationID: conversationID, text: input, date: timeInterval, type: ChatResponseRole.user, modelId: model.id, modelProviderId: model.modelProviderId)
            // add the chat to cache to correct conversation
            await cache.addChatsToConversation([userChat], conversationID: conversationID)
            // if this was newly created convo then update the conversation title to reflect the chat message
            let convo = await cache.getConversation(for: conversationID)
            if let convo = convo, convo.title.isEmpty {
                convo.title = String(input.prefix(35)) // we currently just grab the first 35 chars, needs to be tweaked
                await cache.setConversation(convo, for: conversationID)
                await chatDatabase.addConversation(convo)
            }
            await chatDatabase.addChats([userChat], for: conversationID)
            // refresh the conversation list
            // TODO: only do this for new conversations
            let getConversationList = GetConversationList()
            dispatch(getConversationList)
            // Tell state to publish the data
            let setUserChatMessageAction = SetUserChatMessage(conversationID: conversationID, chatDataModel: userChat)
            dispatch(setUserChatMessageAction)
        }
    }
    
    /// fetchChats
    /// Fetches the saved chats for a conversation from cache/store
    private func fetchChats(conversationID: String) {
        let dispatch = self.dispatch
        Task {
            // first check if we have it in cache
            var chatDataModels = await cache.getChats(conversationID: conversationID)
            if chatDataModels.isEmpty {
                chatDataModels = await chatDatabase.getChats(conversationID: conversationID)
                if !chatDataModels.isEmpty {
                    await cache.addChatsToConversation(chatDataModels, conversationID: conversationID)
                }
            }
            // Tell state to publish data
            let setChatAction = SetChats(conversationID: conversationID, chats: chatDataModels, error: nil)
            dispatch(setChatAction)
        }
    }
    
    /// fetchMockResponses
    /// Convenience method to work with mock data instead of using up your tokens
    private func fetchMockResponses(conversationID: String, model: ProviderModelProtocol) {
        
        Task {[weak self] in
            let oldChatsText = randomStringGenerator(count: 20)
            var chats = [ChatDataModel]()
            var delta:TimeInterval = 60*2
            for text in oldChatsText {
                let date = mockDate.timeIntervalSince1970 - delta
                chats.append(ChatDataModel(id: UUID().uuidString, conversationID: conversationID, text: text, date: date, type: .assistant, modelId: model.id, modelProviderId: model.modelProviderId))
                delta -= 60*2
            }
            let setResponsesAction = SetChats(conversationID: conversationID, chats: chats, error: nil)
            self?.dispatch(setResponsesAction)
            mockDate = mockDate.dayBefore
        }
        
    }
    
    /// fetchMockResponse
    /// Convenience method to work with mock data instead of using up your tokens
    private func fetchMockResponse(action: GetChatResponse) {
        
        Task {[weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let chatBotresponse = randomStringGenerator(count: 1).first else {return}
            let chat = ChatDataModel(id: UUID().uuidString, conversationID: action.conversationID, text: chatBotresponse, date: Date().timeIntervalSince1970, type: .assistant, modelId: action.model.id, modelProviderId: action.model.modelProviderId)
            await self?.cache.addChatsToConversation([chat], conversationID: action.conversationID)
            let setResponsesAction = SetChatResponse(conversationID: action.conversationID, chats: [chat], error: nil)
            self?.dispatch(setResponsesAction)
            await self?.chatDatabase.addChats([chat], for: action.conversationID)
        }
    }
}

// For building mock data
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

// For building mock data
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
