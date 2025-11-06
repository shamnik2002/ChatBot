//
//  ModelProvider.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/5/25.
//
import Foundation

protocol ProviderModelProtocol {
    var name: String {get set}
    var id: String {get set}
    var description: String? {get set}
    var modelProviderId: String {get set}
}

protocol ModelProviderProtocol {
    var name: String {get set}
    var id: String {get set}
    func models() -> [ProviderModelProtocol]
}

struct ProviderModel: ProviderModelProtocol {
    var name: String
    var id: String
    var description: String?
    var modelProviderId: String
}

struct OpenAIProvider: ModelProviderProtocol {
    static let id = "openai"
    var name = "OpenAI"
    var id = "openai"
    
    enum OpenAIModels: String, CaseIterable {
        case gpt_5_nano = "gpt-5-nano"
        case gpt_5_pro = "gpt-5-pro"
        case gpt_5_mini = "gpt-5-mini"
        case gpt_5 = "gpt-5"
        case gpt_5_chat_latest = "gpt-5-chat-latest"
        case gpt_4_1 = "gpt-4.1"
        case gpt_4_1_mini = "gpt-4.1-mini"
        case gpt_4_1_nano = "gpt-4.1-nano"
        
        func name() -> String {
            switch self {
            case .gpt_5_nano: return "GPT 5 Nano"
            case .gpt_5_pro: return "GPT 5 Pro"
            case .gpt_5_mini: return "GPT 5 Mini"
            case .gpt_5: return "GPT 5"
            case .gpt_5_chat_latest: return "GPT 5 Chat Latest"
            case .gpt_4_1: return "GPT 4.1"
            case .gpt_4_1_mini: return "GPT 4.1 mini"
            case .gpt_4_1_nano: return "GPT 4.1 nano"
            }
        }
 
    }
    
    func model(_ type: OpenAIModels) -> ProviderModelProtocol {
        ProviderModel(name: type.name(), id: type.rawValue, modelProviderId: self.id)
    }
    
    func models() -> [any ProviderModelProtocol] {
        return OpenAIModels.allCases.map{ProviderModel(name: $0.name(), id: $0.rawValue, modelProviderId: self.id)}
    }
}
