//
//  OpenAIService.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/5/25.
//
import Combine
import Foundation

protocol ServiceProtocol {
    func fetchResponse(action: GetChatResponse, lastAssisstantChat: ChatDataModel?) async throws -> ([ChatDataModel], [UsageDataModel])
}

final class OpenAIService: ServiceProtocol {
    private var networkService: NetworkProtocol
    private var parser: ParseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parser: ParseProtocol, networkService: NetworkProtocol) {
        self.parser = parser
        self.networkService = networkService
    }
    
    func fetchResponse(action: GetChatResponse, lastAssisstantChat: ChatDataModel?) async throws -> ([ChatDataModel],[UsageDataModel]) {
        // Create the request and parser
        let request = ResponsesRequest(input: action.input, responseId: lastAssisstantChat?.responseId, model: action.model.id)
        let parser = parser
        
        do {
            let start = Date().timeIntervalSince1970
            let data = try await networkService.fetchData(request: request)
            let date = Date().timeIntervalSince1970
            let parsedData: OpenAIResponse = try parser.parse(data: data, type: OpenAIResponse.self)
            let chats = ChatReponsesTransformer.chatDataModelFromOpenAIResponses(parsedData, conversationID: action.conversationID, modelId: action.model.id, date: date)
            let usageData = UsageTransformer.usageModelFromOpenAIResponses(parsedData, conversationID: action.conversationID, modelId: action.model.id, modelProviderId: action.model.modelProviderId, date: date, duration: date - start)
            return (chats, usageData)
        }catch {
            // log error
            throw error
        }
    }
}

/// ChatReponsesTransformer
/// Transforms OpenAI response into ChatDataModel
struct ChatReponsesTransformer {
        
    static func chatDataModelFromOpenAIResponses(_ chatResponses: OpenAIResponse, conversationID: String, modelId: String, date: TimeInterval) -> [ChatDataModel] {
        var chats = [ChatDataModel]()
        let output = chatResponses.output.filter{$0.type == "message"}.first
        let responseId = chatResponses.id
        guard let output else {return []}
        guard let content = output.content?.first else {return []}
        let outputRole = output.role ?? "assistant"
        let role = ChatResponseRole(rawValue: outputRole) ?? .assistant
        let chat = ChatDataModel(id: output.id, conversationID: conversationID , text: content.text, date: date, type: role, responseId: responseId, modelId: modelId, modelProviderId: OpenAIProvider.id)
        chats.append(chat)
        
        return chats
    }
}

struct UsageTransformer {
    static func usageModelFromOpenAIResponses(_ chatResponses: OpenAIResponse, conversationID: String, modelId: String, modelProviderId: String, date: TimeInterval, duration: Double) -> [UsageDataModel] {
        guard let usageData = chatResponses.usage else {
            return []
        }
        return [UsageDataModel(id: UUID().uuidString, conversationID: conversationID, chatMessageID: chatResponses.id, modelId: modelId, modelProviderId: modelProviderId, inputTokens: usageData.input_tokens ?? 0, outputTokens: usageData.output_tokens ?? 0, date: date, duration: duration)]
    }
}
