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
    let response: OpenAIResponse
}

struct SetOldChatResponses: SetChat {
    let responses: [OpenAIResponse]
}

struct SetUserChatMessage: SetChat {
    let chatDataModel: ChatDataModel
}

protocol ConversationAction: ReduxAction {}
protocol ConversationUpdateAction: ReduxMutatingAction {}

struct GetConversationList: ConversationAction {
    
}

struct SetConversationList: ConversationUpdateAction {
    let conversationlist: [ConversationDataModel]
}

struct CreateConversation: ConversationAction {
    let id: String
    let chats: [ChatDataModel]
}

struct SetConversation: ConversationUpdateAction {
    let conversation: ConversationDataModel
}
