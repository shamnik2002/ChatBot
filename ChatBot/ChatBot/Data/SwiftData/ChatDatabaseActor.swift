//
//  ChatDatabaseActor.swift
//  ChatBot
//
//  Created by Shamal nikam on 11/4/25.
//

import SwiftData
import Foundation

actor ChatDatabaseActor {
    
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer
    
    private var modelContext: ModelContext {
        modelExecutor.modelContext
    }
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
    }
    
    func addConversation(_ conversation: ConversationDataModel) {
        let convoModel = ConversationModel(id: conversation.id, title: conversation.title, date: Date().timeIntervalSince1970)
        modelContext.insert(convoModel)
        do {
            try modelContext.save()
        }catch {
            print(error.localizedDescription)
        }
    }
    
    func getConversations() -> [ConversationDataModel] {
        
        var conversationList = [ConversationDataModel]()
        let descriptor = FetchDescriptor<ConversationModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let data = try? modelContext.fetch(descriptor) {
            conversationList = data.map{ConversationDataModel(id: $0.id, title: $0.title, date: $0.date)}
        }
        return conversationList
    }
    
    func deleteConversations(_ conversations: [ConversationDataModel]) {
        conversations.forEach { item in
            
            // Predicate sometimes can't handle keypath so read them in vars here
            let convoId = item.id
            let convoDescriptor = FetchDescriptor<ConversationModel>(
                predicate: #Predicate{$0.id == convoId}
            )
            // fetch the convo
            let chatDescriptor = FetchDescriptor<ChatMessageModel>(
                predicate: #Predicate{$0.conversationID == convoId}
            )
            // delete chats associated with convo from store
            if let chats = try? modelContext.fetch(chatDescriptor) {
                _ = chats.map{modelContext.delete($0)}
            }
            // delete the convo
            if let convoModels = try? modelContext.fetch(convoDescriptor) {
                convoModels.forEach{
                    modelContext.delete($0)
                }
            }
        }
        do {
            try modelContext.save()
        }catch {
            // ideally log errors
            print(error.localizedDescription)
        }
    }
    
    func editConversation(_ conversation: ConversationDataModel) {
        // Predicate sometimes can't handle keypath so read them in vars here
        let convoId = conversation.id
        let convoDescriptor = FetchDescriptor<ConversationModel>(
            predicate: #Predicate{$0.id == convoId}
        )
        // grab the conversation
        if let convoModel = try? modelContext.fetch(convoDescriptor).first {
            // update both title and date so it can be sorted by recency in the list
            convoModel.title = conversation.title
            convoModel.date = conversation.date
            modelContext.insert(convoModel)
        }
        // save it to store
        do {
            try modelContext.save()
        }catch {
            print(error.localizedDescription)
        }
    }
    
    func getLastAssisstantResponseFor(conversationID: String) -> ChatMessageModel? {
        // Predicate sometimes can't handle keypath so read them in vars here
        let role = ChatResponseRole.assistant.rawValue
        // predicate to fetch last response we got from OpenAI to grab the response_id
        // responseId is used to tell OpenAI the context of the conversation
        // Role is how we filter, since we don't want to look at any user messages
        var chatFetchDescriptor = FetchDescriptor<ChatMessageModel>(
            predicate: #Predicate{$0.conversationID == conversationID && $0.role == role},
            sortBy: [SortDescriptor(\.date)]
        )
        chatFetchDescriptor.fetchLimit = 1
        do {
            let chats = try modelContext.fetch(chatFetchDescriptor)
            return chats.first
            
        }catch {
            // TODO: propagate the error back to app or log errors
            // this error is from swiftdata if we fail to fetch data
            print(error)
        }
        return nil
    }
    
    func addChats(_ chats:[ChatDataModel], for conversationID: String) {
        chats.forEach { data in
            let model = ChatMessageModel(id: data.id, conversationID: conversationID, text: data.text, date: data.date, role: data.type, responseId: data.responseId)
            modelContext.insert(model)
        }
        do {
            try modelContext.save()
        }catch {
            print(error.localizedDescription)
        }
    }
    
    func getChats(conversationID: String) -> [ChatDataModel] {
        var chatDataModels = [ChatDataModel]()
        let descriptor = FetchDescriptor<ChatMessageModel>(
            predicate: #Predicate{$0.conversationID == conversationID},
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        if let chats = try? modelContext.fetch(descriptor), !chats.isEmpty {
            chatDataModels = chats.map{ChatDataModel(id: $0.id, conversationID: conversationID, text: $0.text, date: $0.date, type: ChatResponseRole(rawValue: $0.role) ?? .assistant, modelId: $0.modelId, modelProviderId: $0.modelProviderId)}
        }
        return chatDataModels
    }
    
    func addUsageData(_ usageData: [UsageDataModel]){
        usageData.forEach { data in
            let model = UsageModel(id: data.id, conversationID: data.conversationID, chatMessageID: data.chatMessageID, modelId: data.modelId, modelProviderId: data.modelProviderId, inputTokens: data.inputTokens, outputTokens: data.outputTokens, date: data.date, duration: data.duration)
            modelContext.insert(model)
        }
        do {
            try modelContext.save()
        }catch {
            print(error.localizedDescription)
        }
    }
    
    func getUsageData(chatMessageId: String, conversationId: String) -> UsageDataModel? {
        var usageData: UsageDataModel?
        let descriptor = FetchDescriptor<UsageModel>(
            predicate: #Predicate{$0.conversationID == conversationId && $0.chatMessageID == chatMessageId},
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        if let data = try? modelContext.fetch(descriptor).first {
            usageData = UsageDataModel(id: data.id, conversationID: data.conversationID, chatMessageID: data.chatMessageID, modelId: data.modelId, modelProviderId: data.modelProviderId, inputTokens: data.inputTokens, outputTokens: data.outputTokens, date: data.date, duration: data.duration)
        }
        return usageData
    }
    
    func getUsageDataForConversation(_ conversationID: String) -> [UsageDataModel] {
        var usageData = [UsageDataModel]()
        let descriptor = FetchDescriptor<UsageModel>(
            predicate: #Predicate{$0.conversationID == conversationID},
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        if let data = try? modelContext.fetch(descriptor) {
            usageData = data.map{UsageDataModel(id: $0.id, conversationID: $0.conversationID, chatMessageID: $0.chatMessageID, modelId: $0.modelId, modelProviderId: $0.modelProviderId, inputTokens: $0.inputTokens, outputTokens: $0.outputTokens, date: $0.date, duration: $0.duration)}
        }
        return usageData
    }
    
    func getUsageDataForDate(_ date: TimeInterval) -> [UsageDataModel] {
        var usageData = [UsageDataModel]()
        let descriptor = FetchDescriptor<UsageModel>(
            predicate: #Predicate{$0.date == date},
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        if let data = try? modelContext.fetch(descriptor) {
            usageData = data.map{UsageDataModel(id: $0.id, conversationID: $0.conversationID, chatMessageID: $0.chatMessageID, modelId: $0.modelId, modelProviderId: $0.modelProviderId, inputTokens: $0.inputTokens, outputTokens: $0.outputTokens, date: $0.date, duration: $0.duration)}
        }
        return usageData
    }
}
