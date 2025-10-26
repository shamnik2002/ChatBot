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
    let conversationID: String
}

struct GetOldChatResponses: GetChat {
    let conversationID: String
}


protocol SetChat: ReduxMutatingAction {}

struct SetChatResponse: SetChat {
    let conversationID: String
    let chats: [ChatDataModel]
}

struct SetOldChatResponses: SetChat {
    let conversationID: String
    let chats: [ChatDataModel]
}

struct SetUserChatMessage: SetChat {
    let conversationID: String
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
    let conversation: ConversationDataModel
}

struct SetConversation: ConversationUpdateAction {
    let conversation: ConversationDataModel
}
