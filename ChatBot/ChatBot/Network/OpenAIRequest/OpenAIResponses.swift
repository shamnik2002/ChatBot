//
//  OpenAIResponses.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/16/25.
//

import Foundation

//enum 
struct OpenAIResponse: Codable {
    let id: String
    let created_at: TimeInterval
//    let status: String // create an enum with values
    let output: [Output]
//    let error: ResponseError
//    struct ResponseError: Codable {
//        let code: String
//        let message: String
//    }
    struct Output: Codable {
        let type: String // we care about message
        let id: String
        let role: String?
        let content: [Content]?
        
        struct Content: Codable {
            let type: String // we care about output_text
            let text: String // actual data from openAI model
        }
    }    
}

enum ChatResponseRole: String, Codable {
    case user // use this for user input
    case assistant // model always returns this
    case system // to display rate limit issues
}


