//
//  AppActions.swift
//  ChatBot
//
//  Created by Shamal nikam on 10/9/25.
//
import Foundation
import Combine

protocol ReduxAction {}

protocol ReduxMutatingAction: ReduxAction {}

protocol GetChat: ReduxAction {}
struct GetChatResponse: GetChat {
    let input: String
}

struct GetOldChatResponses: GetChat {
    
}


protocol SetChat: ReduxMutatingAction {}
struct SetChatResponse: SetChat {
    let response: ChatResponse
}

struct SetOldChatResponses: SetChat {
    let responses: [ChatResponse]
}

struct SetUserChatMessage: SetChat {
    let chatDataModel: ChatDataModel
}
