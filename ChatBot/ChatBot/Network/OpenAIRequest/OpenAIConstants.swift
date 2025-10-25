//
//  OpenAIConstants.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

struct OpenAIContants {
    static let host = "api.openai.com"
    static let headers:[String: String] = ["Content-Type": "application/json", OpenAIContants.authBearerKey: "\(OpenAIContants.authBearerValuePrefix)\(OpenAIContants.API_Secret)"]
    static let authBearerKey = "Authorization"
    static let authBearerValuePrefix = "Bearer "
    static let modelKey = "model"
    static let model = "gpt-5-nano"
    static let inputKey = "input"
    static let API_Secret  = "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"
}
