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

/// Generic Get action for any chat related request
protocol GetChat: ReduxAction {
    var retryAttempt: Int {get set}
}

// Fetch response for user input
struct GetChatResponse: GetChat {
    let input: String
    let conversationID: String
    var retryAttempt: Int
    var model: ProviderModel = OpenAIProvider.model(.gpt_5_mini)
}

// Fetch old chats from store for now (eventually plan to fetch it from cloukit perhaps)
struct GetChats: GetChat {
    var retryAttempt: Int = 0
    let conversationID: String
}

/// Generix Set action for chat related state updates
protocol SetChat: ReduxMutatingAction {}

// Action to let State know to publish chat response we received for user input to listners
struct SetChatResponse: SetChat {
    let conversationID: String
    let chats: [ChatDataModel]
    let error: ChatError?
}

// Action to let State know to publish old chats we received from store/BE to listners
struct SetChats: SetChat {
    let conversationID: String
    let chats: [ChatDataModel]
    let error: ChatError?
}

// Action to let State know about the user input which has been added to cache/store and UI can now display
struct SetUserChatMessage: SetChat {
    let conversationID: String
    let chatDataModel: ChatDataModel
}

/// Generic Get Conversation related actions
protocol ConversationAction: ReduxAction {}

/// Generic Update Conversation related actions
protocol ConversationUpdateAction: ReduxMutatingAction {}

// Fetch conversationlist from store/BE
// TODO: now fetches all, eventually we need page limit, offset to allow pagination
struct GetConversationList: ConversationAction {
}

// Action to let State know we have data and to publisher to listeners
struct SetConversationList: ConversationUpdateAction {
    let conversationlist: [ConversationDataModel]
}

// Action to create a new conversation
struct CreateConversation: ConversationAction {
    let conversation: ConversationDataModel
}

// Action to let state know conversation was created and to publish to listners
struct SetConversation: ConversationUpdateAction {
    let conversation: ConversationDataModel
}

// Action to delete a conversation
struct DeleteConversations: ConversationAction {
    let conversations: [ConversationDataModel]
}

// Action to let state know conversation was updated and to publish to listners
struct EditConversation: ConversationAction {
    let conversation: ConversationDataModel
}


//MARK: Settings action
protocol SettingsAction: ReduxAction{}
protocol SettingsMutatingAction: ReduxMutatingAction{}

struct GetSettingsObject: SettingsAction {
    let key: String
}

struct UpdateSettingsObject: SettingsAction {
    let key: String
    let value: Codable
}

struct SetSettingsObject: SettingsMutatingAction {
    let key: String
    let value: Codable?
    let error: Error?
}


//MARK: Usage actions
protocol UsageAction: ReduxAction{}
protocol UsageMutatingAction: ReduxMutatingAction{}

struct GetUsageByChat: UsageAction {
    let chatMessageId: String
    let conversationId: String
}

struct GetUsageByConversation: UsageAction {
    let conversationId: String
    let pageLimit: Int
    let pageOffset: Int
}

struct GetUsageByDate: UsageAction {
    let date: TimeInterval
    let pageLimit: Int
    let pageOffset: Int
}

struct SetUsage: UsageMutatingAction {
    let usageData: [UsageDataModel]
    let originalAction: UsageAction
}

struct GetUsageTotal: UsageAction {
    let type: UsageTotalsType
}

struct SetUsageTotal: UsageMutatingAction {
    let usageTotal: UsageTotals
    let isFinished: Bool
}
