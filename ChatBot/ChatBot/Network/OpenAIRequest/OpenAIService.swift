//
//  OpenAIService.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/5/25.
//
import Combine
import Foundation

protocol ServiceProtocol {
    func fetchResponse(action: GetChatResponse, lastAssisstantChat: ChatDataModel?) async throws -> [ChatDataModel]
}

final class OpenAIService: ServiceProtocol {
    private var networkService: NetworkProtocol
    private var parser: ParseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parser: ParseProtocol, networkService: NetworkProtocol) {
        self.parser = parser
        self.networkService = networkService
    }
    
    func fetchResponse(action: GetChatResponse, lastAssisstantChat: ChatDataModel?) async throws -> [ChatDataModel] {
        // Create the request and parser
        let request = ResponsesRequest(input: action.input, responseId: lastAssisstantChat?.responseId, model: action.model.id)
        let parser = parser
        
        do {
            let data = try await networkService.fetchData(request: request)
            let parsedData: OpenAIResponse = try parser.parse(data: data, type: OpenAIResponse.self)
            let chats = ChatReponsesTransformer.chatDataModelFromOpenAIResponses(parsedData, conversationID: action.conversationID, modelId: action.model.id)
            return chats
        }catch {
            // log error
            throw error
        }
    }
}

/// ChatReponsesTransformer
/// Transforms OpenAI response into ChatDataModel
struct ChatReponsesTransformer {
        
    static func chatDataModelFromOpenAIResponses(_ chatResponses: OpenAIResponse, conversationID: String, modelId: String) -> [ChatDataModel] {
        var chats = [ChatDataModel]()
        let output = chatResponses.output.filter{$0.type == "message"}.first
        let responseId = chatResponses.id
        guard let output else {return []}
        guard let content = output.content?.first else {return []}
        let outputRole = output.role ?? "assistant"
        let role = ChatResponseRole(rawValue: outputRole) ?? .assistant
        let chat = ChatDataModel(id: output.id, conversationID: conversationID , text: content.text, date: Date().timeIntervalSince1970, type: role, responseId: responseId, modelId: modelId, modelProviderId: OpenAIProvider.id)
        chats.append(chat)
        
        return chats
    }
}
